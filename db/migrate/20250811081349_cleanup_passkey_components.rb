# db/migrate/YYYYMMDDHHMMSS_cleanup_passkey_components.rb
class CleanupPasskeyComponents < ActiveRecord::Migration[8.0]
  def up
    # passkeysテーブルが存在すれば削除
    drop_table :passkeys if table_exists?(:passkeys)

    # usersテーブルからパスキー関連カラムを削除
    remove_column :users, :passkey_enabled if column_exists?(:users, :passkey_enabled)
    remove_column :users, :webauthn_enabled if column_exists?(:users, :webauthn_enabled)
    remove_column :users, :webauthn_id if column_exists?(:users, :webauthn_id)
  end

  def down
    # 必要に応じて復元処理
    create_table :passkeys do |t|
      t.references :user, null: false, foreign_key: true
      t.string :identifier, null: false
      t.text :public_key, null: false
      t.integer :sign_count, null: false, default: 0
      t.datetime :last_used_at
      t.string :label
      t.timestamps
    end

    add_index :passkeys, :identifier, unique: true
    add_column :users, :passkey_enabled, :boolean, default: false, null: false
  end
end