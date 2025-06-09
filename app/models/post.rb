class Post < ApplicationRecord
  belongs_to :user
  belongs_to :category
  has_many :comments, dependent: :destroy
  has_many :likes, dependent: :destroy
  has_many :post_tags, dependent: :destroy
  has_many :tags, through: :post_tags
  has_one_attached :image

  # recent スコープを定義
  scope :recent, -> { order(created_at: :desc) }

  validates :title, presence: true, length: { maximum: 100 }
  validates :content, presence: true, length: { maximum: 5000 }
  validates :category_id, presence: true
  # nameのバリデーションを削除（Postにnameカラムは存在しない）
  # validates :name, presence: true

  # 画像のバリデーション（active_storage_validations使用）
  validates :image, content_type: { in: %w[image/jpeg image/gif image/png],
                                    message: "有効な画像形式（JPEG、PNG、GIF）を選択してください" },
            size: { less_than: 10.megabytes,
                    message: "ファイルサイズは10MB以下にしてください" },
            allow_blank: true

  # タグリスト用の仮想属性
  attr_accessor :tag_list

  # コールバック：投稿保存後にタグを処理
  after_save :update_tags

  # いいね機能
  def liked_by?(user)
    return false unless user
    likes.exists?(user: user)
  end

  def likes_count
    likes.count
  end

  # タグリストの取得（編集フォーム用）
  def tag_list
    @tag_list || tags.pluck(:name).join(', ')
  end

  # タグリストの設定（フォームからの入力用）
  def tag_list=(value)
    @tag_list = value
  end

  # 検索スコープ
  scope :search_by_title_and_content, ->(query) {
    where("title ILIKE ? OR content ILIKE ?", "%#{query}%", "%#{query}%")
  }

  scope :by_category, ->(category_id) {
    where(category_id: category_id) if category_id.present?
  }

  private

  # タグの更新処理
  def update_tags
    return unless @tag_list

    # 既存のタグ関連付けを削除
    post_tags.destroy_all

    # 新しいタグを処理
    tag_names = @tag_list.split(',').map(&:strip).reject(&:blank?)

    tag_names.each do |tag_name|
      # タグを検索または作成
      tag = Tag.find_or_create_by(name: tag_name)
      # 投稿とタグを関連付け
      post_tags.create(tag: tag)
    end
  end
end