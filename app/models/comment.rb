class Comment < ApplicationRecord
  belongs_to :user
  belongs_to :post

  validates :content, presence: true, length: { maximum: 500 }

  # 表示順スコープ（新しい順）
  scope :ordered_for_display, -> { order(created_at: :desc) }
end
