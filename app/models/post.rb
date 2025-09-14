
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

  # 画像保存後にEXIF情報を削除（S3アップロード後に処理）
  def process_images_for_exif_removal
    return unless images.attached?
    
    # 添付された画像を処理してEXIF削除
    images.each do |image|
      next unless image.content_type&.start_with?('image/')
      
      begin
        Rails.logger.info "Processing image for EXIF removal: #{image.filename}"
        
        # 非同期でEXIF削除処理を実行
        RemoveExifJob.perform_later(image)
        
      rescue => e
        Rails.logger.error "EXIF removal job enqueue error: #{e.message}"
      end
    end
  end
end
