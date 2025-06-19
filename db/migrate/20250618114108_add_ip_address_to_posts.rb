class AddIpAddressToPosts < ActiveRecord::Migration[8.0]
  def change
    add_column :posts, :ip_address, :string
  end
end
