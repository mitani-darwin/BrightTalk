class AllowNullCategoryIdInPosts < ActiveRecord::Migration[8.0]
  def up
    # category_id のNOT NULL制約を削除
    change_column_null :posts, :category_id, true
  end

  def down
    # rollback時はNOT NULL制約を復元
    # ただし、nullの値がある場合はデフォルトカテゴリーを設定してから制約を追加
    default_category = Category.find_or_create_by(name: "その他")
    Post.where(category_id: nil).update_all(category_id: default_category.id)
    change_column_null :posts, :category_id, false
  end
end
