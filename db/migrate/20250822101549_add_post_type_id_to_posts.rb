class AddPostTypeIdToPosts < ActiveRecord::Migration[8.0]
  def change
    add_reference :posts, :post_type, foreign_key: true, index: true
  end
end
