class Article < ApplicationRecord
  belongs_to :category
  has_many :article_tags, dependent: :destroy
  has_many :tags, through: :article_tags

  validates :title, presence: true, length: { maximum: 100 }
  validates :content, presence: true

  scope :by_category, ->(category) { where(category: category) }
  scope :tagged_with, ->(tag_name) { joins(:tags).where(tags: { name: tag_name }) }

  def tag_list
    tags.pluck(:name).join(', ')
  end

  def tag_list=(names)
    tag_names = names.split(',').map(&:strip).reject(&:blank?)
    self.tags = Tag.find_or_create_by_names(tag_names)
  end
end