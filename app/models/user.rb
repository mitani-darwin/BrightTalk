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

  # バリデーション
  validates :name, presence: true
  validates :avatar, content_type: { in: %w[image/jpeg image/png image/gif],
                                     message: "JPEG、JPG、PNG、GIF形式のファイルを選択してください" },
            size: { less_than: 5.megabytes, message: "5MB以下のファイルを選択してください" }

  # Postsにrecentスコープを追加するために必要
  scope :recent, -> { order(created_at: :desc) }

  # パスワード強度のカスタムバリデーション
  validate :password_complexity, if: :password_required?

  # デフォルト値の設定
  attribute :webauthn_enabled, :boolean, default: true

  def webauthn_id
    # WebAuthn用のユーザーIDを生成（ユーザーIDをbase64エンコード）
    @webauthn_id ||= Base64.strict_encode64("user_#{id}")
  end

  # WebAuthn認証が有効で、かつ認証情報が登録されている場合のみWebAuthn認証を要求
  def webauthn_required?
    webauthn_enabled? && webauthn_credentials.exists?
  end

  def has_webauthn_credentials?
    webauthn_credentials.exists?
  end

  # パスワード認証を許可するか（修正版）
  def password_authentication_allowed?
    # WebAuthnが無効、またはWebAuthn認証情報が未登録の場合はパスワード認証を許可
    # WebAuthnが有効でも、明示的にパスワード認証を選択した場合は許可
    !webauthn_enabled? || !webauthn_credentials.exists? || allow_password_fallback?
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

  # WebAuthn登録後にパスワードを無効化（削除または無効化）
  def disable_password_after_webauthn
    # パスワードを完全に無効化せず、WebAuthn設定のみ更新
    if has_webauthn_credentials? && webauthn_enabled?
      # パスワードは残す（フォールバック用）
      Rails.logger.info "WebAuthn設定完了: ユーザー#{id}のWebAuthn認証が有効になりました"
    end
  end

  # valid_password?メソッドを削除または修正
  # Deviseのデフォルト動作を維持し、独自のロジックは他の場所で処理
  # def valid_password?は削除

  # パスワード変更専用の検証メソッド
  def valid_password_for_change?(password)
    # パスワード変更専用の検証メソッド（WebAuthn有効でも動作）
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
