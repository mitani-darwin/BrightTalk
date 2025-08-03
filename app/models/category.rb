
class Category < ApplicationRecord
  # Article関連の不要な関連を削除
  # has_many :articles, dependent: :destroy

  has_many :posts, dependent: :destroy

  validates :name, presence: true, uniqueness: true, length: { maximum: 50 }
  validates :description, length: { maximum: 200 }

  # Article関連のスコープを削除し、Post関連のみ残す
  # scope :with_articles, -> { joins(:articles).distinct }
  scope :with_posts, -> { joins(:posts).distinct }
end
