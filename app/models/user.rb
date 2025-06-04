class User < ApplicationRecord
  has_secure_password

  has_many :posts, dependent: :destroy
  has_many :comments, dependent: :destroy
  has_many :likes, dependent: :destroy
  has_many :liked_posts, through: :likes, source: :post

  # バリデーション
  validates :email, presence: true, uniqueness: true
  validates :name, presence: true

  # 特定の投稿にいいねしているかどうかを判定
  def liked?(post)
    likes.exists?(post: post)
  end
end