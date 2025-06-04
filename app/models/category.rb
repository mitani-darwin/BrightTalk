class Category < ApplicationRecord
  has_many :articles, dependent: :destroy
  has_many :posts, dependent: :destroy

  validates :name, presence: true, uniqueness: true
  validates :name, length: { maximum: 50 }

  scope :with_articles, -> { joins(:articles).distinct }
  scope :with_posts, -> { joins(:posts).distinct }
end