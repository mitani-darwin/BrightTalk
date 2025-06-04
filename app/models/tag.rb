class Tag < ApplicationRecord
  has_many :article_tags, dependent: :destroy
  has_many :articles, through: :article_tags

  validates :name, presence: true, uniqueness: true
  validates :name, length: { maximum: 30 }

  scope :popular, -> { joins(:articles).group('tags.id').order('COUNT(articles.id) DESC') }

  def self.find_or_create_by_names(tag_names)
    tag_names.map do |name|
      find_or_create_by(name: name.strip)
    end
  end
end