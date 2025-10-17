class AddFieldsToComments < ActiveRecord::Migration[8.0]
  def change
    add_column :comments, :paid, :boolean, null: false, default: false
    add_column :comments, :points, :integer, null: false, default: 0
    add_column :comments, :latitude, :decimal, precision: 10, scale: 6
    add_column :comments, :longitude, :decimal, precision: 10, scale: 6
    add_column :comments, :client_ip, :string

    add_index :comments, [:paid, :points, :created_at]
    add_index :comments, [:paid, :created_at]
  end
end


