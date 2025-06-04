class Post < ApplicationRecord
  belongs_to :user
  has_many :comments, dependent: :destroy

  validates :title, presence: true, length: { maximum: 100 }
  validates :content, presence: true

  scope :recent, -> { order(created_at: :desc) }
end