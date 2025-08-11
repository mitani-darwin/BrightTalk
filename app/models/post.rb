class Post < ApplicationRecord
  belongs_to :user
  belongs_to :category, optional: true

  has_many :post_tags, dependent: :destroy
  has_many :tags, through: :post_tags

  validates :title, presence: true, length: { maximum: 100 }
  validates :content, presence: true

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

  private

  def set_default_status
    self.status ||= :published
  end
end