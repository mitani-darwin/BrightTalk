class User < ApplicationRecord
  # Deviseモジュール（データベース認証可能とする）
  devise :database_authenticatable, :registerable, :recoverable, :rememberable, :validatable, :confirmable

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

  # WebAuthn認証が必須
  def webauthn_required?
    persisted? && !has_webauthn_credentials?
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
    return false if has_webauthn_credentials?
    super
  end
end