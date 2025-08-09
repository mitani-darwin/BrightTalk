class User < ApplicationRecord
  # Deviseモジュール（データベース認証可能とする）
  devise :database_authenticatable, :registerable, :confirmable,
         :recoverable, :rememberable, :validatable

  has_many :posts, dependent: :destroy
  has_many :comments, dependent: :destroy
  has_many :likes, dependent: :destroy
  has_many :liked_posts, through: :likes, source: :post
  has_many :webauthn_credentials, dependent: :destroy

  # アバター画像の関連付け
  has_one_attached :avatar

  # パスキー
  has_many :passkeys, dependent: :destroy

  # バリデーション
  validates :name, presence: true
  validates :avatar, content_type: { in: %w[image/jpeg image/png image/gif],
                                     message: "JPEG、JPG、PNG、GIF形式のファイルを選択してください" },
            size: { less_than: 5.megabytes, message: "5MB以下のファイルを選択してください" }

  # Postsにrecentスコープを追加するために必要
  scope :recent, -> { order(created_at: :desc) }

  # パスワード強度のカスタムバリデーション
  validate :password_complexity, if: :password_required?

  # デフォルト値の設定（webauthn_enabledをpasskey_enabledに統一）
  attribute :passkey_enabled, :boolean, default: true

  def webauthn_id
    # WebAuthn用のユーザーIDを生成（ユーザーIDをbase64エンコード）
    @webauthn_id ||= Base64.strict_encode64("user_#{id}")
  end

  # Passkey認証が有効で、かつ認証情報が登録されている場合のみPasskey認証を要求
  def passkey_required?
    passkey_enabled? && passkeys.exists?
  end

  # 後方互換性のため（徐々に削除予定）
  def webauthn_required?
    passkey_required?
  end

  def has_passkey_credentials?
    passkeys.exists?
  end

  # 後方互換性のため（徐々に削除予定）
  def has_webauthn_credentials?
    has_passkey_credentials?
  end

  # パスワード認証を許可するか
  def password_authentication_allowed?
    # Passkeyが無効、またはPasskey認証情報が未登録の場合はパスワード認証を許可
    !passkey_enabled? || !passkeys.exists? || allow_password_fallback?
  end

  # パスワード認証のフォールバックを許可するかの判定
  def allow_password_fallback?
    # 必要に応じてセッションや他の条件でパスワード認証を許可
    true # 一時的に常に許可（後で条件を追加可能）
  end

  # 特定の投稿にいいねしているかどうかを判定
  def liked?(post)
    likes.exists?(post: post)
  end

  # アバター表示用ヘルパーメソッド
  def avatar_or_default
    if avatar.attached?
      avatar
    else
      nil
    end
  end

  # Passkey登録後の処理
  def disable_password_after_passkey
    # パスワードを完全に無効化せず、Passkey設定のみ更新
    if has_passkey_credentials? && passkey_enabled?
      # パスワードは残す（フォールバック用）
      Rails.logger.info "Passkey設定完了: ユーザー#{id}のPasskey認証が有効になりました"
    end
  end

  # パスワード変更専用の検証メソッド
  def valid_password_for_change?(password)
    # パスワード変更専用の検証メソッド（Passkey有効でも動作）
    return false if encrypted_password.blank?

    BCrypt::Password.new(encrypted_password) == password
  rescue BCrypt::Errors::InvalidHash
    false
  end

  private

  def password_complexity
    return if password.blank?

    errors.add(:password, :too_weak) unless strong_password?(password)
  end

  def strong_password?(password)
    # 英数字記号をそれぞれ1文字以上含む
    has_letter = password.match?(/[a-zA-Z]/)
    has_number = password.match?(/[0-9]/)
    has_symbol = password.match?(/[^a-zA-Z0-9]/)

    return false unless has_letter && has_number && has_symbol

    # 推測しやすいパスワードをチェック
    !weak_password?(password)
  end

  def weak_password?(password)
    weak_patterns = [
      # 連続した文字（abc, 123, など）
      /(.)\1{2,}/,                           # 同じ文字が3回以上連続
      /(?:abc|bcd|cde|def|efg|fgh|ghi|hij|ijk|jkl|klm|lmn|mno|nop|opq|pqr|qrs|rst|stu|tuv|uvw|vwx|wxy|xyz)/i,
      /(?:012|123|234|345|456|567|678|789)/,
      /(?:987|876|765|654|543|432|321|210)/,

      # キーボードパターン
      /(?:qwerty|asdfgh|zxcvbn|qwertyui|asdfghjk|zxcvbnm)/i,
      /(?:1qaz|2wsx|3edc|4rfv|5tgb|6yhn|7ujm|8ik|9ol|0p)/i,

      # よくあるパスワードパターン
      /^password/i,
      /^123456/,
      /^admin/i,
      /^user/i,
      /^test/i,
      /^guest/i,
      /^login/i,

      # 年号パターン
      /(?:19|20)\d{2}/,

      # 単純な組み合わせ
      /^[a-z]+[0-9]+$/i,        # 文字 + 数字のみ
      /^[0-9]+[a-z]+$/i        # 数字 + 文字のみ
    ]

    # ユーザー名やメールアドレスの一部が含まれているかチェック
    return true if name.present? && password.downcase.include?(name.downcase)
    return true if email.present? && password.downcase.include?(email.split("@").first.downcase)

    # 弱いパターンのいずれかにマッチするかチェック
    weak_patterns.any? { |pattern| password.match?(pattern) }
  end

  def password_required?
    !persisted? || !password.nil? || !password_confirmation.nil?
  end
end