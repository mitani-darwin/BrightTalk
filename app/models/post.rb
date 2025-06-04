class Post < ApplicationRecord
  belongs_to :user
  has_many :comments, dependent: :destroy

  # 画像添付機能
  has_one_attached :image

  validates :title, presence: true
  validates :content, presence: true

  # スコープの追加
  scope :recent, -> { order(created_at: :desc) }

  # 画像のバリデーション（カスタムバリデーション）
  validate :image_validation

  private

  def image_validation
    return unless image.attached?

    # ファイル形式のチェック
    acceptable_types = %w[image/jpeg image/jpg image/png image/gif]
    unless acceptable_types.include?(image.blob.content_type)
      errors.add(:image, "は JPEG、PNG、GIF ファイルのみアップロード可能です")
    end

    # ファイルサイズのチェック
    if image.blob.byte_size > 10.megabytes
      errors.add(:image, "は10MB以下にしてください")
    end
  end
end