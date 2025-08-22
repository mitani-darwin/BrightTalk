
class Category < ApplicationRecord
  # Article関連の不要な関連を削除
  # has_many :articles, dependent: :destroy

  has_many :posts, dependent: :destroy

  # 階層構造のアソシエーション
  belongs_to :parent, class_name: 'Category', optional: true
  has_many :children, class_name: 'Category', foreign_key: 'parent_id', dependent: :destroy

  validates :name, presence: true, uniqueness: { scope: :parent_id }, length: { maximum: 50 }
  validates :description, length: { maximum: 200 }
  validate :prevent_circular_reference

  # Article関連のスコープを削除し、Post関連のみ残す
  # scope :with_articles, -> { joins(:articles).distinct }
  scope :with_posts, -> { joins(:posts).distinct }
  scope :root_categories, -> { where(parent_id: nil) }
  scope :sub_categories, -> { where.not(parent_id: nil) }

  # 階層構造のヘルパーメソッド
  def root?
    parent_id.nil?
  end

  def leaf?
    children.empty?
  end

  def depth
    return 0 if root?
    1 + parent.depth
  end

  def ancestors
    result = []
    current = parent
    visited = Set.new
    
    while current && !visited.include?(current.id)
      visited.add(current.id)
      result.unshift(current)
      current = current.parent
    end
    
    result
  end

  def descendants
    children.flat_map { |child| [child] + child.descendants }
  end

  def full_name(separator: ' > ')
    if root?
      name
    else
      ancestors.map(&:name).join(separator) + separator + name
    end
  end

  private

  def prevent_circular_reference
    return unless parent_id

    if parent_id == id
      errors.add(:parent_id, '自分自身を親カテゴリーに設定することはできません')
    elsif ancestors.include?(self)
      errors.add(:parent_id, '循環参照が発生します')
    end
  end
end
