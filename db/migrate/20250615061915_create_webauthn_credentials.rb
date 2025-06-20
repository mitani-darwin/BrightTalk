class CreateWebauthnCredentials < ActiveRecord::Migration[8.0]
  def change
    create_table :webauthn_credentials do |t|
      t.references :user, null: false, foreign_key: true
      t.string :external_id, null: false
      t.text :public_key, null: false
      t.string :nickname
      t.integer :sign_count, default: 0
      t.datetime :last_used_at

      t.timestamps
    end

    add_index :webauthn_credentials, :external_id, unique: true
  end
end
