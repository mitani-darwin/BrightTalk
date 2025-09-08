class AddPasskeyEnabledToUsers < ActiveRecord::Migration[8.0]
  def change
    add_column :users, :passkey_enabled, :boolean, default: true, null: false

    # 既存ユーザーのデフォルト値を設定
    reversible do |dir|
      dir.up do
        # WebAuthn認証情報を持っているユーザーはtrue、持っていないユーザーもtrue（デフォルト）
        User.reset_column_information
        User.update_all(passkey_enabled: true)
      end
    end
  end
end
