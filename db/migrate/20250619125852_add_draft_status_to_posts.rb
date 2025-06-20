class AddDraftStatusToPosts < ActiveRecord::Migration[8.0]
  def change
    add_column :posts, :draft, :boolean, default: false
    add_index :posts, :draft
  end
end
