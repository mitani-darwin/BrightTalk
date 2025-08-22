class PostType < ApplicationRecord
  has_many :posts, dependent: :destroy

  validates :name, presence: true, uniqueness: true, length: { maximum: 50 }
  validates :description, length: { maximum: 200 }

  scope :with_posts, -> { joins(:posts).distinct }

  def posts_count
    posts.count
  end
end