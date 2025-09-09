
class Post < ApplicationRecord
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

  # Markdownを HTMLに変換
  def content_as_html
    return "" if content.blank?
    
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
    
    markdown.render(content).html_safe
  end

  private

  def set_default_status
    self.status ||= :published
  end

  # 自動保存されたドラフトかどうかを判定
  def auto_saved_draft?
    draft? && auto_save == true
  end
end
