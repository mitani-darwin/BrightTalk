class WebauthnCredential < ApplicationRecord
  belongs_to :user
  
  validates :external_id, presence: true, uniqueness: true
  validates :public_key, presence: true
  validates :nickname, presence: true, length: { maximum: 255 }
  validates :sign_count, presence: true, numericality: { greater_than_or_equal_to: 0 }
  
  scope :active, -> { where('last_used_at IS NULL OR last_used_at > ?', 30.days.ago) }
  scope :recent, -> { order(created_at: :desc) }
  
  # パスキーのエイリアス（PasskeySessionsControllerとの互換性のため）
  alias_attribute :identifier, :external_id
  
  def display_name
    nickname.presence || "パスキー #{created_at.strftime('%Y/%m/%d')}"
  end
  
  def recently_used?
    last_used_at && last_used_at > 7.days.ago
  end
  
  def update_last_used!
    touch(:last_used_at)
  end
end