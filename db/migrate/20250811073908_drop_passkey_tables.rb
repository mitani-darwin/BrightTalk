class DropPasskeyTables < ActiveRecord::Migration[8.0]
  def up
    # パスキー関連テーブルを削除
    drop_table :passkeys if table_exists?(:passkeys)

    # ユーザーテーブルからパスキー関連カラムを削除
    if column_exists?(:users, :passkey_enabled)
      remove_column :users, :passkey_enabled
    end
  end

  def down
    # 必要に応じて復元用の処理を記述
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
