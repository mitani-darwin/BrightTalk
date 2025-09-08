class AddPurposeAndStructureToPosts < ActiveRecord::Migration[8.0]
  def change
    add_column :posts, :purpose, :string
    add_column :posts, :target_audience, :string
    add_column :posts, :post_type, :integer, default: 0
    add_column :posts, :key_points, :text
    add_column :posts, :expected_outcome, :text

    add_index :posts, :purpose
    add_index :posts, :post_type
  end
end
