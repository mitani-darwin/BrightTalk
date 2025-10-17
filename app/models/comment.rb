class Comment < ApplicationRecord
  belongs_to :user
  belongs_to :post

  validates :content, presence: true, length: { maximum: 500 }

  # ポイントは0以上の整数
  validates :points, numericality: { only_integer: true, greater_than_or_equal_to: 0 }, allow_nil: true

  # 表示順スコープ
  # 1) 有料(paid=true)を優先し、ポイント降順、次に作成日の新しい順
  # 2) 無課金(paid=false)は作成日の新しい順
  scope :ordered_for_display, lambda {
    order(Arel.sql("paid DESC, CASE WHEN paid THEN 0 ELSE 1 END ASC, points DESC, created_at DESC"))
  }
end
