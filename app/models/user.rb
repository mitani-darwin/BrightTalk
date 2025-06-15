
class User < ApplicationRecord
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable, :trackable and :omniauthable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable, :confirmable

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

  def webauthn_id
    # WebAuthn用のユーザーIDを生成（ユーザーIDをbase64エンコード）
    WebAuthn.generate_user_id
  end


  def has_webauthn_credentials?
    webauthn_credentials.exists?
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