
class Tag < ApplicationRecord
  # Article関連の不要な関連を削除
  # has_many :article_tags, dependent: :destroy
  # has_many :articles, through: :article_tags

  has_many :post_tags, dependent: :destroy
  has_many :posts, through: :post_tags

  validates :name, presence: true, uniqueness: true
  validates :name, length: { maximum: 30 }

  # Article関連のスコープを削除し、Post関連のみ残す
  # scope :popular, -> { joins(:articles).group('tags.id').order('COUNT(articles.id) DESC') }
  scope :popular_for_posts, -> { joins(:posts).group('tags.id').order('COUNT(posts.id) DESC') }

  def self.find_or_create_by_names(tag_names)
    tag_names.map do |name|
      find_or_create_by(name: name.strip)
    end
  end
end