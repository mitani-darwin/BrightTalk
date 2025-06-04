
class AddCategoryToPosts < ActiveRecord::Migration[8.0]
  def up
    # カテゴリーカラムを追加（null許可）
    add_reference :posts, :category, null: true, foreign_key: true

    # デフォルトカテゴリーを作成
    default_category = Category.find_or_create_by(name: "その他")

    # 既存のpostsにデフォルトカテゴリーを設定
    Post.update_all(category_id: default_category.id)

    # NOT NULL制約を追加
    change_column_null :posts, :category_id, false
  end

  def down
    remove_reference :posts, :category, foreign_key: true
  end
end