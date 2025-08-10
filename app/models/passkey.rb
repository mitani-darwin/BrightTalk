class Passkey < ApplicationRecord
  belongs_to :user

  validates :identifier, presence: true, uniqueness: true
  validates :public_key, presence: true
  validates :sign_count, presence: true, numericality: { greater_than_or_equal_to: 0 }

  # devise-passkeys 互換メソッド
  def self.normalize_identifier(id)
    Base64.urlsafe_encode64(id, padding: false)
  end

  # 最後の使用時刻を更新
  def update_last_used!
    update!(last_used_at: Time.current)
  end

  # サインカウントを更新
  def update_sign_count!(new_count)
    update!(sign_count: new_count) if new_count > sign_count
  end
end