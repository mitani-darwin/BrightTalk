class User < ApplicationRecord
  devise :database_authenticatable, :registerable, :confirmable,
         :recoverable, :rememberable, :validatable,
         :passkey_authenticatable

  has_many :posts, dependent: :destroy
  has_many :comments, dependent: :destroy
  has_many :likes, dependent: :destroy
  has_many :liked_posts, through: :likes, source: :post
  has_many :webauthn_credentials, dependent: :destroy
  has_many :passkeys, dependent: :destroy

  has_one_attached :avatar

  validates :name, presence: true
  validates :avatar, content_type: { in: %w[image/jpeg image/png image/gif],
                                     message: "JPEG、JPG、PNG、GIF形式のファイルを選択してください" },
            size: { less_than: 5.megabytes, message: "5MB以下のファイルを選択してください" }

  scope :recent, -> { order(created_at: :desc) }
  validate :password_complexity, if: :password_required?

  def liked?(post)
    likes.exists?(post: post)
  end

  def avatar_or_default
    if avatar.attached?
      avatar
    else
      nil
    end
  end

  # パスキー関連のメソッド
  def has_passkeys?
    passkeys.exists?
  end

  # 旧メソッド名との互換性のため
  alias_method :has_passkey_credentials?, :has_passkeys?

  def passkey_enabled?
    has_passkeys?
  end

  private

  def password_complexity
    return if password.blank?
    errors.add(:password, :too_weak) unless strong_password?(password)
  end

  def strong_password?(password)
    has_letter = password.match?(/[a-zA-Z]/)
    has_number = password.match?(/[0-9]/)
    has_symbol = password.match?(/[^a-zA-Z0-9]/)
    return false unless has_letter && has_number && has_symbol
    !weak_password?(password)
  end

  def weak_password?(password)
    weak_patterns = [
      /(.)\1{2,}/,
      /(?:abc|bcd|cde|def|efg|fgh|ghi|hij|ijk|jkl|klm|lmn|mno|nop|opq|pqr|qrs|rst|stu|tuv|uvw|vwx|wxy|xyz)/i,
      /(?:012|123|234|345|456|567|678|789)/,
      /(?:987|876|765|654|543|432|321|210)/,
      /(?:qwerty|asdfgh|zxcvbn|qwertyui|asdfghjk|zxcvbnm)/i,
      /(?:1qaz|2wsx|3edc|4rfv|5tgb|6yhn|7ujm|8ik|9ol|0p)/i,
      /^password/i, /^123456/, /^admin/i, /^user/i, /^test/i, /^guest/i, /^login/i,
      /(?:19|20)\d{2}/, /^[a-z]+[0-9]+$/i, /^[0-9]+[a-z]+$/i
    ]

    return true if name.present? && password.downcase.include?(name.downcase)
    return true if email.present? && password.downcase.include?(email.split("@").first.downcase)
    weak_patterns.any? { |pattern| password.match?(pattern) }
  end

  def password_required?
    !persisted? || !password.nil? || !password_confirmation.nil?
  end
end