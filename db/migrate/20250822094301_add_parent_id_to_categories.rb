class AddParentIdToCategories < ActiveRecord::Migration[8.0]
  def change
    add_column :categories, :parent_id, :integer
    add_index :categories, :parent_id
    add_foreign_key :categories, :categories, column: :parent_id
  end
end
