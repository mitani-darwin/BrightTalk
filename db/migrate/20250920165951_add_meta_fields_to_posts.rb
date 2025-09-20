class AddMetaFieldsToPosts < ActiveRecord::Migration[8.0]
  def change
    add_column :posts, :meta_description, :text
    add_column :posts, :og_title, :string
    add_column :posts, :og_description, :text
    add_column :posts, :og_image, :string
  end
end
