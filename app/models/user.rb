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

  def header_image_or_default
    if header_image.attached?
      header_image
    else
      nil
    end
  end

  def has_social_links?
    [twitter_url, github_url].any?(&:present?)
  end

  def extended_stats
    {
      posts_count: posts.count,
      published_posts_count: posts.where(published: true).count,
      draft_posts_count: posts.where(draft: true).count,
      comments_count: comments.count,
      likes_given: likes.count,
      likes_received: Like.joins(:post).where(posts: { user: self }).count,
      most_liked_post: posts.joins(:likes).group('posts.id').order('COUNT(likes.id) DESC').first
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
      /(.)\\1{2,}/,
      /(?:abc|bcd|cde|def|efg|fgh|ghi|hij|ijk|jkl|klm|lmn|mno|nop|opq|pqr|qrs|rst|stu|tuv|uvw|vwx|wxy|xyz)/i,
      /(?:012|123|234|345|456|567|678|789)/,
      /(?:987|876|765|654|543|432|321|210)/,

      # キーボードパターン
      /(?:qwerty|asdfgh|zxcvbn|qwertyui|asdfghjk|zxcvbnm)/i,
      /(?:1qaz|2wsx|3edc|4rfv|5tgb|6yhn|7ujm|8ik|9ol|0p)/i,
      /^password/i, /^123456/, /^admin/i, /^user/i, /^test/i, /^guest/i, /^login/i,
      /(?:19|20)\\d{2}/, /^[a-z]+[0-9]+$/i, /^[0-9]+[a-z]+$/i,

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
    # パスキー登録フロー中はパスワード複雑性バリデーションをスキップ
    return false if persisted? && has_passkeys?

    !persisted? || !password.nil? || !password_confirmation.nil?
  end
end
