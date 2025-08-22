class RemovePostTypeFromPosts < ActiveRecord::Migration[8.0]
  def change
    remove_column :posts, :post_type, :integer
  end
end
