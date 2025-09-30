class User < ApplicationRecord
  extend FriendlyId
  friendly_id :name, use: :slugged

  devise :database_authenticatable, :registerable, :confirmable,
         :recoverable, :rememberable

  has_many :posts, dependent: :destroy
  has_many :comments, dependent: :destroy
  has_many :likes, dependent: :destroy
  has_many :liked_posts, through: :likes, source: :post

  # WebAuthn/Passkey認証
  has_many :webauthn_credentials, dependent: :destroy
  alias_method :passkeys, :webauthn_credentials

  has_one_attached :avatar
  has_one_attached :header_image

  validates :name, presence: true
  validates :email, presence: true
  validates :avatar, content_type: { in: %w[image/jpeg image/png image/gif],
                                     message: "JPEG、JPG、PNG、GIF形式のファイルを選択してください" },
            size: { less_than: 5.megabytes, message: "5MB以下のファイルを選択してください" }
  validates :header_image, content_type: { in: %w[image/jpeg image/png image/gif],
                                          message: "JPEG、JPG、PNG、GIF形式のファイルを選択してください" }

  # Social links validations
  validates :twitter_url, format: { with: /\A(https?:\/\/)?(www\.)?(twitter\.com|x\.com)\/\w+\z/i,
                                   message: "正しいTwitterのURLを入力してください" },
            allow_blank: true
  validates :github_url, format: { with: /\Ahttps?:\/\/(www\.)?github\.com\/\w+\z/i,
                                  message: "正しいGitHubのURLを入力してください" },
            allow_blank: true

  scope :recent, -> { order(created_at: :desc) }

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

  def header_image_or_default
    if header_image.attached?
      header_image
    else
      nil
    end
  end

  def has_social_links?
    [ twitter_url, github_url ].any?(&:present?)
  end

  def extended_stats
    {
      posts_count: posts.count,
      published_posts_count: posts.where(published: true).count,
      draft_posts_count: posts.where(draft: true).count,
      comments_count: comments.count,
      likes_given: likes.count,
      likes_received: Like.joins(:post).where(posts: { user: self }).count,
      most_liked_post: posts.joins(:likes).group("posts.id").order("COUNT(likes.id) DESC").first
    }
  end

  # Passkey関連メソッド
  def has_passkeys?
    webauthn_credentials.exists?
  end

  def active_passkeys
    webauthn_credentials.active
  end

  def passkey_count
    webauthn_credentials.count
  end

  # 重複する確認メール送信を防ぐメソッド
  def send_confirmation_instructions_once
    # 確認済みの場合は送信しない
    return if confirmed?
    
    # 最近（5分以内）に確認メールが送信されている場合は送信しない
    return if confirmation_sent_at.present? && confirmation_sent_at > 5.minutes.ago
    
    # 通常の確認メール送信処理を実行
    send_confirmation_instructions
  end

  private
end
