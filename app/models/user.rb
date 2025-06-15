
class User < ApplicationRecord
  # パスワード認証を無効にし、WebAuthnのみを使用
  devise :registerable, :recoverable, :rememberable, :validatable, :confirmable

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

  # パスワード認証を無効化
  def valid_password?(password)
    false
  end

  def password_required?
    false
  end

  def email_required?
    true
  end

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
end