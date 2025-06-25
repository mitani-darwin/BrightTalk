
class Post < ApplicationRecord
  belongs_to :user
  belongs_to :category, optional: true
  has_many :comments, dependent: :destroy
  has_many :likes, dependent: :destroy
  has_many :post_tags, dependent: :destroy
  has_many :tags, through: :post_tags
  has_many_attached :images  # 複数の画像を添付

  validates :title, presence: true, length: { maximum: 255 }
  validates :content, presence: true
  # 画像のバリデーション（複数画像対応）
  validates :images, content_type: [ "image/png", "image/jpeg", "image/gif" ]

  # スコープの追加
  scope :recent, -> { order(created_at: :desc) }
  scope :published, -> { where(draft: false) }
  scope :drafts, -> { where(draft: true) }

  # デフォルトで下書きではない状態に設定
  after_initialize :set_default_draft, if: :new_record?

  # tag_list機能を追加
  attr_accessor :tag_list

  after_save :save_tags

  def tag_list
    @tag_list || tags.pluck(:name).join(", ")
  end

  def tag_list=(names)
    @tag_list = names
  end

  def published?
    !draft?
  end

  def draft?
    draft
  end

  private

  def set_default_draft
    self.draft = false if draft.nil?
  end

  def save_tags
    return unless @tag_list

    # 既存のタグ関連付けを削除
    self.post_tags.destroy_all

    # 新しいタグを作成・関連付け
    tag_names = @tag_list.split(",").map(&:strip).reject(&:blank?)
    tag_names.each do |name|
      tag = Tag.find_or_create_by(name: name)
      self.post_tags.create(tag: tag)
    end
  end
end