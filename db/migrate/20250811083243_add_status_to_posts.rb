class AddStatusToPosts < ActiveRecord::Migration[8.0]
  def change
    add_column :posts, :status, :integer, default: 1, null: false

    # 既存の投稿は全て公開済みとして設定
    reversible do |dir|
      dir.up do
        Post.reset_column_information
        Post.update_all(status: 1) # published
      end
    end

    add_index :posts, :status
  end
end