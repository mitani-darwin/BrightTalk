class ChangeWebauthnEnabledDefaultToTrue < ActiveRecord::Migration[8.0]
  def up
    # デフォルト値を変更
    change_column_default :users, :webauthn_enabled, from: false, to: true

    # 既存のレコードでwebauthn_enabledがfalseまたはnullのものをtrueに更新
    User.where(webauthn_enabled: [false, nil]).update_all(webauthn_enabled: true)
  end

  def down
    # ロールバック時は元のデフォルト値に戻す
    change_column_default :users, :webauthn_enabled, from: true, to: false
  end
end