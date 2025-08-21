class RecreateWebauthnCredentials < ActiveRecord::Migration[8.0]
  def change
    create_table :webauthn_credentials do |t|
      t.integer :user_id, null: false
      t.string :external_id, null: false
      t.text :public_key, null: false
      t.string :nickname
      t.integer :sign_count, default: 0
      t.datetime :last_used_at
      t.timestamps null: false
    end

    add_index :webauthn_credentials, :external_id, unique: true
    add_index :webauthn_credentials, :user_id
    add_foreign_key :webauthn_credentials, :users
  end
end
