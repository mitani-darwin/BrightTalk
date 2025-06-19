
class Post < ApplicationRecord
  belongs_to :user
  belongs_to :category, optional: true
  has_many :comments, dependent: :destroy
  has_many :likes, dependent: :destroy
  has_many :post_tags, dependent: :destroy
  has_many :tags, through: :post_tags
  has_many_attached :images  # 複数の画像を添付

  validates :title, presence: true, length: { maximum: 255 }
  validates :content, presence: true
  # 画像のバリデーション（複数画像対応）
  validates :images, content_type: ['image/png', 'image/jpeg', 'image/gif'],
            size: { less_than: 5.megabytes }

  # スコープの追加
  scope :recent, -> { order(created_at: :desc) }
  scope :published, -> { where(draft: false) }
  scope :drafts, -> { where(draft: true) }

  # デフォルトで下書きではない状態に設定
  after_initialize :set_default_draft, if: :new_record?

  def published?
    !draft?
  end

  def draft?
    draft
  end

  private

  def set_default_draft
    self.draft = false if draft.nil?
  end
end