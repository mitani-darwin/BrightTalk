class CompletePasskeyCleanup < ActiveRecord::Migration[8.0]
  def up
    # すべてのパスキー関連テーブルを削除
    drop_table :passkeys if table_exists?(:passkeys)
    drop_table :webauthn_credentials if table_exists?(:webauthn_credentials)

    # usersテーブルからすべてのパスキー・WebAuthn関連カラムを削除
    remove_column :users, :webauthn_enabled if column_exists?(:users, :webauthn_enabled)
    remove_column :users, :webauthn_id if column_exists?(:users, :webauthn_id)
    remove_column :users, :passkey_enabled if column_exists?(:users, :passkey_enabled)

    # その他の可能性のあるカラム
    remove_column :users, :webauthn_user_id if column_exists?(:users, :webauthn_user_id)
  end

  def down
    # 必要に応じて復元処理（通常は不要）
  end
end
