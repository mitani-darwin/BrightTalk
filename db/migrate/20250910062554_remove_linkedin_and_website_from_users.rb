class RemoveLinkedinAndWebsiteFromUsers < ActiveRecord::Migration[8.0]
  def change
    remove_column :users, :linkedin_url, :string
    remove_column :users, :website_url, :string
  end
end
