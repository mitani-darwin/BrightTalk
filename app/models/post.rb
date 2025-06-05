class Post < ApplicationRecord
  belongs_to :user
  belongs_to :category
  has_many :comments, dependent: :destroy
  has_many :likes, dependent: :destroy
  has_many :liked_users, through: :likes, source: :user
  has_many :post_tags, dependent: :destroy
  has_many :tags, through: :post_tags

  # 複数から単数に変更
  has_one_attached :image

  validates :title, presence: true
  validates :content, presence: true

  scope :recent, -> { order(created_at: :desc) }
  scope :by_category, ->(category_id) { where(category_id: category_id) if category_id.present? }
  scope :tagged_with, ->(tag_name) { joins(:tags).where(tags: { name: tag_name }) if tag_name.present? }

  # 検索機能のスコープを修正 - SQLite3では ILIKE の代わりに LIKE COLLATE NOCASE を使用
  scope :search, ->(query) {
    return all if query.blank?

    where(
      "title LIKE :query COLLATE NOCASE OR content LIKE :query COLLATE NOCASE OR EXISTS (
        SELECT 1 FROM post_tags pt
        JOIN tags t ON pt.tag_id = t.id
        WHERE pt.post_id = posts.id AND t.name LIKE :query COLLATE NOCASE
      )",
      query: "%#{query}%"
    )
  }

  def likes_count
    likes.count
  end

  def tag_list
    tags.pluck(:name).join(', ')
  end

  def tag_list=(names)
    tag_names = names.split(',').map(&:strip).reject(&:blank?)
    self.tags = tag_names.map do |name|
      Tag.find_or_create_by(name: name.downcase)
    end
  end

  private

  def image_validation
    return unless image.attached?

    if image.blob.byte_size > 5.megabytes
      errors.add(:image, 'は5MB以下である必要があります')
    end
  end
end