class Like < ApplicationRecord
  belongs_to :user
  belongs_to :post

  # 同じユーザーが同じ投稿に複数回いいねできないようにする
  validates :user_id, uniqueness: { scope: :post_id }
end