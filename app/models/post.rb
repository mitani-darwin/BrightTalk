
class Post < ApplicationRecord
  belongs_to :user
  belongs_to :category
  has_many :comments, dependent: :destroy
  has_many :likes, dependent: :destroy
  has_many :liked_users, through: :likes, source: :user
  has_many :post_tags, dependent: :destroy
  has_many :tags, through: :post_tags

  # 画像添付機能
  has_one_attached :image

  validates :title, presence: true
  validates :content, presence: true
  validates :category, presence: true

  # スコープの追加
  scope :recent, -> { order(created_at: :desc) }
  scope :by_category, ->(category_id) { where(category_id: category_id) if category_id.present? }
  scope :tagged_with, ->(tag_name) { joins(:tags).where(tags: { name: tag_name }) }

  # 画像のバリデーション（カスタムバリデーション）
  validate :image_validation

  # いいね数を取得
  def likes_count
    likes.count
  end

  def tag_list
    tags.map(&:name).join(', ')
  end

  def tag_list=(names)
    tag_names = names.split(',').map(&:strip).reject(&:blank?)
    self.tags = Tag.find_or_create_by_names(tag_names)
  end

  private

  def image_validation
    return unless image.attached?

    # ファイル形式のチェック
    acceptable_types = %w[image/jpeg image/jpg image/png image/gif]
    unless acceptable_types.include?(image.blob.content_type)
      errors.add(:image, "は JPEG、PNG、GIF ファイルのみアップロード可能です")
    end

    # ファイルサイズのチェック
    if image.blob.byte_size > 10.megabytes
      errors.add(:image, "は10MB以下にしてください")
    end
  end
end