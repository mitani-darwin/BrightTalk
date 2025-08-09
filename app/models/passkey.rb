class Passkey < ApplicationRecord
  belongs_to :user

  validates :identifier, presence: true, uniqueness: true
  validates :public_key, presence: true
  validates :sign_count, presence: true, numericality: { greater_than_or_equal_to: 0 }

  before_validation :ensure_identifier

  # 移行用のクラスメソッド
  def self.from_webauthn_credential(webauthn_credential)
    new(
      user: webauthn_credential.user,
      identifier: normalize_identifier(webauthn_credential.external_id),
      public_key: webauthn_credential.public_key,
      sign_count: webauthn_credential.sign_count || 0,
      last_used_at: webauthn_credential.updated_at,
      label: "移行済みデバイス"
    )
  end

  # identifier の正規化
  def self.normalize_identifier(external_id)
    case external_id
    when String
      if external_id.match?(/\A[A-Za-z0-9_-]+\z/) && !external_id.include?('=')
        external_id
      else
        begin
          decoded = Base64.decode64(external_id)
          Base64.urlsafe_encode64(decoded, padding: false)
        rescue ArgumentError
          external_id.tr('+/', '-_').gsub('=', '')
        end
      end
    when Array
      Base64.urlsafe_encode64(external_id.pack("C*"), padding: false)
    else
      Base64.urlsafe_encode64(external_id.to_s, padding: false)
    end
  end

  private

  def ensure_identifier
    self.identifier ||= SecureRandom.urlsafe_base64(32)
  end
end