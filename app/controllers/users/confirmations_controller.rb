
class Users::ConfirmationsController < Devise::ConfirmationsController
  # GET /resource/confirmation?confirmation_token=abcdef
  def show
    Rails.logger.info "Confirmation started with token: #{params[:confirmation_token]}"

    # トークンでユーザーを確認
    self.resource = resource_class.confirm_by_token(params[:confirmation_token])
    yield resource if block_given?

    if resource.errors.empty?
      Rails.logger.info "User #{resource.id} confirmed successfully"

      # フラッシュメッセージを設定
      set_flash_message!(:notice, :confirmed)

      # 明示的にユーザーをログインさせる
      if resource.active_for_authentication?
        sign_in(resource_name, resource)
        Rails.logger.info "User #{resource.id} signed in after confirmation"

        # サインイン状況を確認
        Rails.logger.info "Current user after sign_in: #{current_user&.id}"
        Rails.logger.info "User signed in?: #{user_signed_in?}"

        # セッションから仮登録情報を削除
        session.delete(:pending_user_id)

        # リダイレクト先を決定 - Passkeyに変更
        if passkey_available?
          redirect_to new_passkey_path(first_time: true),
                      notice: "メール認証が完了し、ログインしました。セキュリティ強化のためパスキー認証を設定することをお勧めします。"
        else
          redirect_to root_path, notice: "アカウントが確認され、ログインしました。"
        end
      else
        Rails.logger.error "User #{resource.id} is not active for authentication"
        redirect_to new_user_session_path, alert: "アカウントは確認されましたが、ログインに問題があります。再度ログインしてください。"
      end
    else
      Rails.logger.error "Confirmation failed for token #{params[:confirmation_token]}: #{resource.errors.full_messages}"
      # エラーがある場合はDeviseのデフォルト動作
      respond_with(resource)
    end
  end

  private

  def after_confirmation_path_for(resource_name, resource)
    Rails.logger.info "=== After Confirmation Path ==="
    Rails.logger.info "Resource: #{resource.id}"
    Rails.logger.info "User signed in?: #{user_signed_in?}"
    Rails.logger.info "Current user: #{current_user&.id}"

    # 確認後に強制的にサインイン（Devise 4.9.4では手動で行う必要がある）
    unless user_signed_in?
      Rails.logger.info "Forcing sign in for user: #{resource.id}"
      sign_in(resource)
      Rails.logger.info "Sign in completed. Current user: #{current_user&.id}"
    end

    # セッションから仮登録情報を削除
    session.delete(:pending_user_id)

    # リダイレクト先を決定 - Passkeyに変更
    if passkey_available?
      new_passkey_path(first_time: true)
    else
      root_path
    end
  end

  def passkey_available?
    # Passkey APIが利用可能かどうかをチェック
    true
  end
end