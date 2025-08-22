
class Post < ApplicationRecord
  belongs_to :user
  belongs_to :category, optional: true

  has_many :post_tags, dependent: :destroy
  has_many :tags, through: :post_tags
  has_many :likes, dependent: :destroy
  has_many :comments, dependent: :destroy

  # Active Storage for images
  has_many_attached :images

  validates :title, presence: true, length: { maximum: 100 }
  validates :content, presence: true
  validates :purpose, presence: true, length: { maximum: 200 }
  validates :target_audience, presence: true, length: { maximum: 100 }

  # 投稿状態のenum定義
  enum :status, {
    draft: 0,      # 下書き
    published: 1   # 公開済み
  }

  # 投稿タイプのenum定義
  enum :post_type, {
    knowledge_sharing: 0,    # 知識共有
    question: 1,            # 質問・相談
    discussion: 2,          # 議論・討論
    tutorial: 3,            # チュートリアル・手順
    experience_sharing: 4,   # 体験談・事例
    news_update: 5,         # ニュース・更新情報
    opinion: 6              # 意見・考察
  }

  # 最新の投稿を取得するスコープ
  scope :recent, -> { order(created_at: :desc) }
  scope :published_posts, -> { where(status: :published) }
  scope :draft_posts, -> { where(status: :draft) }

  # デフォルトは公開状態
  after_initialize :set_default_status, if: :new_record?

  private

  def set_default_status
    self.status ||= :published
  end
end