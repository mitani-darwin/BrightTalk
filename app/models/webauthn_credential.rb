class WebauthnCredential < ApplicationRecord
  belongs_to :user

  validates :external_id, presence: true, uniqueness: true
  validates :public_key, presence: true
  validates :sign_count, presence: true, numericality: { greater_than_or_equal_to: 0 }

  def update_sign_count!(new_count)
    update!(sign_count: new_count, last_used_at: Time.current)
  end
end