class PostType < ApplicationRecord
  has_many :posts, dependent: :destroy

  validates :name, presence: true, uniqueness: true, length: { maximum: 50 }
  validates :description, length: { maximum: 200 }

  scope :with_posts, -> { joins(:posts).distinct }

  def posts_count
    posts.count
  end

  # 日本語の表示名を返す（フォームや一覧で使用）
  def display_name
    case name
    when 'knowledge_sharing' then '知識共有'
    when 'question' then '質問・相談'
    when 'discussion' then '議論・討論'
    when 'tutorial' then 'チュートリアル・手順'
    when 'experience_sharing' then '体験談・事例'
    when 'news_update' then 'ニュース・更新情報'
    when 'opinion' then '意見・考察'
    else
      name
    end
  end
end