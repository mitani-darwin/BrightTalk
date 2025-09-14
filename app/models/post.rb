
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
  after_commit :process_images_for_exif_removal, on: [:create, :update]

  # Markdownを HTMLに変換（attachment:URLsを適切に処理）
  def content_as_html
    return "" if content.blank?
    
    # まずMarkdown処理を行う
    renderer = Redcarpet::Render::HTML.new(
      filter_html: true,
      no_links: false,
      no_images: false,
      hard_wrap: true,
      link_attributes: { target: "_blank", rel: "noopener" }
    )
    
    markdown = Redcarpet::Markdown.new(renderer,
      autolink: true,
      tables: true,
      fenced_code_blocks: true,
      strikethrough: true,
      superscript: true,
      underline: true,
      quote: true,
      footnotes: true
    )
    
    # Markdownを適用
    html_content = markdown.render(content)

    # HTMLから attachment: URLsを見つけて置き換え
    processed_html = html_content.gsub(/src="attachment:([^"]+)"/) do |match|
      filename = $1

      # 正規化されたファイル名で検索
      normalize_name = ->(name) do
        s = name.to_s.strip
        begin
          s = CGI.unescape(s)
        rescue
          # ignore malformed escape sequences
        end
        s = s.unicode_normalize(:nfc) if s.respond_to?(:unicode_normalize)
        s
      end

      placeholder_name = normalize_name.call(filename)

      # 対応する画像を検索
      if images.attached?
        matching_image = images.find do |img|
          normalize_name.call(img.filename.to_s) == placeholder_name
        end

        if matching_image
          actual_url = Rails.application.routes.url_helpers.rails_blob_path(matching_image, only_path: true)
          %Q(src="#{ERB::Util.html_escape(actual_url)}" alt="#{ERB::Util.html_escape(filename)}" class="img-fluid rounded my-3 clickable-image" style="max-width: 100%; cursor: pointer;" data-bs-toggle="modal" data-bs-target="#imageModal" data-image-src="#{ERB::Util.html_escape(actual_url)}")
        else
          match # 見つからない場合は元のまま
        end
      else
        match # 画像がない場合は元のまま
      end
    end

    processed_html.html_safe
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
      next unless attachment.blob&.content_type&.start_with?('image/')
      next if attachment.blob.metadata['exif_removed'] == true

      begin
        Rails.logger.info "Processing image for EXIF removal: #{attachment.filename}"
        
        # 画像データをダウンロードしてEXIF削除を実行
        attachment.blob.open do |tempfile|
          require 'ruby-vips'
          
          # Vipsで画像を読み込み（EXIFは自動的に読み込まれる）
          image = Vips::Image.new_from_file(tempfile.path, access: :sequential)
          
          # EXIFを完全に削除して新しい画像を作成
          processed_tempfile = Tempfile.new(['vips_processed_', File.extname(attachment.filename.to_s)])
          
          # オプションでEXIFを削除してファイルに書き込み
          write_options = { strip: true }
          
          # ファイル形式に応じて最適な書き込みオプションを設定
          case attachment.content_type
          when 'image/jpeg'
            write_options.merge!({ Q: 95, optimize_coding: true, strip: true })
          when 'image/png'
            write_options.merge!({ compression: 6, strip: true })
          when 'image/webp'
            write_options.merge!({ Q: 95, strip: true })
          end
          
          # 処理済み画像を書き込み
          image.write_to_file(processed_tempfile.path, **write_options)
          
          # 元のblobを処理済み画像で置き換え
          processed_data = File.read(processed_tempfile.path)
          
          # 新しいチェックサムを計算（base64形式でActive Storageが期待する形式）
          new_checksum = Digest::MD5.file(processed_tempfile.path).base64digest
          
          # blobのメタデータを更新
          attachment.blob.update!(
            checksum: new_checksum,
            byte_size: processed_data.bytesize,
            metadata: attachment.blob.metadata.merge('exif_removed' => true, 'processed_by' => 'ruby-vips')
          )
          
          # S3に処理済み画像をアップロード
          if attachment.blob.service.respond_to?(:upload)
            # ファイルIOを使用してS3にアップロード（StringIOよりも安全）
            File.open(processed_tempfile.path, 'rb') do |file|
              attachment.blob.service.upload(
                attachment.blob.key,
                file,
                checksum: new_checksum,
                content_type: attachment.content_type
              )
            end
          end
          
          Rails.logger.info "EXIF情報をruby-vipsで削除完了: #{attachment.filename}"
          
          # 一時ファイルを削除
          processed_tempfile.close!
          processed_tempfile.unlink
        end
        
      rescue => e
        Rails.logger.error "ruby-vipsによるEXIF削除中にエラーが発生しました (#{attachment.blob&.filename}): #{e.class.name}: #{e.message}"
        Rails.logger.error "Stack trace: #{e.backtrace.first(3).join(", ")}"
      end
    end
  end
end
