
class Post < ApplicationRecord
  extend FriendlyId
  friendly_id :title, use: :slugged

  belongs_to :user
  belongs_to :category, optional: true
  belongs_to :post_type, optional: true

  # 自動保存フラグ（バリデーション制御用）
  attr_accessor :auto_save

  has_many :post_tags, dependent: :destroy
  has_many :tags, through: :post_tags
  has_many :likes, dependent: :destroy
  has_many :comments, dependent: :destroy

  # Active Storage for images
  has_many_attached :images
  # Active Storage for videos
  has_many_attached :videos

  validates :title, presence: true, length: { maximum: 100 }, unless: :auto_saved_draft?
  validates :content, presence: true, unless: :auto_saved_draft?
  validates :purpose, presence: true, length: { maximum: 200 }, unless: :draft?
  validates :target_audience, presence: true, length: { maximum: 100 }, unless: :draft?
  validates :category_id, presence: true, unless: :draft?
  validates :post_type_id, presence: true, unless: :draft?

  # 投稿状態のenum定義
  enum :status, {
    draft: 0,      # 下書き
    published: 1   # 公開済み
  }


  # 最新の投稿を取得するスコープ
  scope :recent, -> { order(created_at: :desc) }
  scope :published_posts, -> { where(status: :published) }
  scope :draft_posts, -> { where(status: :draft) }

  # デフォルトは公開状態
  after_initialize :set_default_status, if: :new_record?

  # 画像保存後にEXIF情報を削除（S3アップロード後に処理）
  after_commit :process_images_for_exif_removal, on: [ :create, :update ], unless: -> { Rails.env.test? }

  # 動画保存後に非同期でS3にアップロード
  after_commit :process_videos_for_async_upload, on: [ :create, :update ], unless: -> { Rails.env.test? }

  # Markdownを HTMLに変換（attachment:URLsを適切に処理）
  def content_as_html
    return "" if content.blank?
    ApplicationController.helpers.format_content_with_images(content, self)
  end

  # 同じ投稿者の前の投稿を取得
  def previous_post_by_author
    user.posts.published
        .where("created_at < ?", created_at)
        .order(created_at: :desc)
        .first
  end

  # 同じ投稿者の次の投稿を取得
  def next_post_by_author
    user.posts.published
        .where("created_at > ?", created_at)
        .order(created_at: :asc)
        .first
  end

  private

  def set_default_status
    self.status ||= :published
  end

  # 自動保存されたドラフトかどうかを判定
  def auto_saved_draft?
    draft? && auto_save == true
  end

  # 画像保存前の前処理（EXIF削除）
  def process_images_for_exif_removal
    return unless images.attached?

    images.each do |attachment|
      next unless attachment.blob&.content_type&.start_with?("image/")
      next if attachment.blob.metadata["exif_removed"] == true

      begin
        Rails.logger.info "Processing image for EXIF removal: #{attachment.filename}"

        # 新しいblobを作成してEXIF削除を実行
        Tempfile.create([ "original_", File.extname(attachment.filename.to_s) ], binmode: true) do |original_tempfile|
          # S3から元の画像をダウンロード（直接ダウンロード）
          attachment.blob.service.download(attachment.blob.key) do |chunk|
            original_tempfile.write(chunk)
          end
          original_tempfile.rewind

          begin
            require "ruby-vips"
          rescue LoadError => e
            Rails.logger.warn "ruby-vips not available, skipping EXIF removal for #{attachment.filename}: #{e.message}"
            return
          end

          # Vipsで画像を読み込み（EXIFは自動的に読み込まれる）
          image = Vips::Image.new_from_file(original_tempfile.path, access: :sequential)

          # EXIFを完全に削除して新しい画像を作成
          Tempfile.create([ "vips_processed_", File.extname(attachment.filename.to_s) ]) do |processed_tempfile|
            # オプションでEXIFを削除してファイルに書き込み
            write_options = { strip: true }

            # ファイル形式に応じて最適な書き込みオプションを設定
            case attachment.content_type
            when "image/jpeg"
              write_options.merge!({ Q: 95, optimize_coding: true, strip: true })
            when "image/png"
              write_options.merge!({ compression: 6, strip: true })
            when "image/webp"
              write_options.merge!({ Q: 95, strip: true })
            end

            # 処理済み画像を書き込み
            image.write_to_file(processed_tempfile.path, **write_options)

            # 新しいチェックサムを計算（base64形式でActive Storageが期待する形式）
            new_checksum = Digest::MD5.file(processed_tempfile.path).base64digest
            processed_data_size = File.size(processed_tempfile.path)

            # S3に処理済み画像をアップロード
            if attachment.blob.service.respond_to?(:upload)
              File.open(processed_tempfile.path, "rb") do |file|
                attachment.blob.service.upload(
                  attachment.blob.key,
                  file,
                  checksum: new_checksum,
                  content_type: attachment.content_type
                )
              end
            end

            # blobのメタデータを更新（S3アップロード後）
            attachment.blob.update!(
              checksum: new_checksum,
              byte_size: processed_data_size,
              metadata: attachment.blob.metadata.merge("exif_removed" => true, "processed_by" => "ruby-vips")
            )

            Rails.logger.info "EXIF情報をruby-vipsで削除完了: #{attachment.filename}"
          end
        end

      rescue => e
        Rails.logger.error "ruby-vipsによるEXIF削除中にエラーが発生しました (#{attachment.blob&.filename}): #{e.class.name}: #{e.message}"
        Rails.logger.error "Stack trace: #{e.backtrace.first(3).join(", ")}"
      end
    end
  end

  # 動画保存後の非同期S3アップロード処理
  def process_videos_for_async_upload
    return unless videos.attached?

    videos.each do |attachment|
      next unless attachment.blob&.content_type&.start_with?("video/")
      next if attachment.blob.metadata["async_upload_completed"] == true

      begin
        Rails.logger.info "Processing video for async s3 upload: #{attachment.filename}"

        # 非同期ジョブをエンキュー
        VideoUploadJob.perform_later(attachment)

        Rails.logger.info "VideoUploadJob enqueued for: #{attachment.filename}"

      rescue => e
        Rails.logger.error "動画の非同期アップロードジョブのエンキュー中にエラーが発生しました (#{attachment.blob&.filename}): #{e.class.name}: #{e.message}"
        Rails.logger.error "Stack trace: #{e.backtrace.first(3).join(", ")}"
      end
    end
  end
end
