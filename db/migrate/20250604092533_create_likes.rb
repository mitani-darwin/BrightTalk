class CreateLikes < ActiveRecord::Migration[8.0]
  def change
    create_table :likes do |t|
      t.references :user, null: false, foreign_key: true
      t.references :post, null: false, foreign_key: true

      t.timestamps
    end

    # 同じユーザーが同じ投稿に複数回いいねできないようにする
    add_index :likes, [ :user_id, :post_id ], unique: true
  end
end
