class RemovePaidPointsAndLocationFromComments < ActiveRecord::Migration[8.0]
  def change
    remove_index :comments, [:paid, :points, :created_at]
    remove_index :comments, [:paid, :created_at]

    remove_column :comments, :paid, :boolean, null: false, default: false
    remove_column :comments, :points, :integer, null: false, default: 0
    remove_column :comments, :latitude, :decimal, precision: 10, scale: 6
    remove_column :comments, :longitude, :decimal, precision: 10, scale: 6
  end
end
