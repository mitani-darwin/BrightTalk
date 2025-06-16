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
                                     message: 'JPEG、JPG、PNG、GIF形式のファイルを選択してください' },
            size: { less_than: 5.megabytes, message: '5MB以下のファイルを選択してください' }

  # Postsにrecentスコープを追加するために必要
  scope :recent, -> { order(created_at: :desc) }

  def webauthn_id
    # WebAuthn用のユーザーIDを生成（ユーザーIDをbase64エンコード）
    WebAuthn.generate_user_id
  end

  def has_webauthn_credentials?
    webauthn_credentials.exists?
  end

  # WebAuthn認証が有効で、かつ認証情報が登録されている場合のみWebAuthn認証を要求
  def webauthn_required?
    webauthn_enabled? && webauthn_credentials.exists?
  end

  # パスワード認証を許可するか
  def password_authentication_allowed?
    !webauthn_enabled? || !webauthn_credentials.exists?
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

  # WebAuthn登録後にパスワードを無効化
  def disable_password_after_webauthn
    if has_webauthn_credentials?
      self.encrypted_password = ""
      save(validate: false)
    end
  end

  # WebAuthn認証が設定されている場合、パスワード認証をスキップ
  def valid_password?(password)
    # ログイン時のみWebAuthn認証を強制し、パスワード変更時は通常のバリデーションを使用
    return false if has_webauthn_credentials? && caller.any? { |line| line.include?('sessions_controller') }
    super
  end

  # または、より明示的なメソッドを追加
  def valid_password_for_change?(password)
    # パスワード変更専用の検証メソッド（WebAuthn有効でも動作）
    BCrypt::Password.new(encrypted_password) == password
  rescue BCrypt::Errors::InvalidHash
    false
  end
end