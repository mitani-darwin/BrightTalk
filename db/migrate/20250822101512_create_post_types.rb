class CreatePostTypes < ActiveRecord::Migration[8.0]
  def change
    create_table :post_types do |t|
      t.string :name, null: false
      t.text :description

      t.timestamps
    end
    
    add_index :post_types, :name, unique: true
  end
end
