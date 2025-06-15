# app/controllers/users/confirmations_controller.rb
class Users::ConfirmationsController < Devise::ConfirmationsController
  protected

  def after_confirmation_path_for(resource_name, resource)
    # メール確認完了時にユーザーを自動的にログインさせる
    sign_in(resource)

    # ユーザーがメール確認を完了した時のリダイレクト先
    # まずは成功メッセージを表示してWebAuthn設定に進む
    flash[:notice] = 'メール確認が完了しました！アカウント登録が完了しました。セキュリティ向上のため、WebAuthn認証を設定してください。'
    new_webauthn_credential_path
  end

  def after_resending_confirmation_instructions_path_for(resource_name)
    # 確認メール再送信後のリダイレクト先
    root_path
  end
end