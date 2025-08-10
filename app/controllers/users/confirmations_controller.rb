class Users::ConfirmationsController < Devise::ConfirmationsController
  # GET /resource/confirmation?confirmation_token=abcdef
  def show
    Rails.logger.info "Confirmation started with token: #{params[:confirmation_token]}"

    self.resource = resource_class.confirm_by_token(params[:confirmation_token])
    yield resource if block_given?

    if resource.errors.empty?
      Rails.logger.info "User #{resource.id} confirmed successfully"
      set_flash_message!(:notice, :confirmed)

      if resource.active_for_authentication?
        sign_in(resource_name, resource)
        Rails.logger.info "User #{resource.id} signed in after confirmation"
        session.delete(:pending_user_id)

        # ⭐ 正しいパスキールートを使用
        if passkey_available?
          redirect_to new_user_passkey_path(first_time: true),
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
      respond_with(resource)
    end
  end

  private

  def after_confirmation_path_for(resource_name, resource)
    Rails.logger.info "=== After Confirmation Path ==="
    Rails.logger.info "Resource: #{resource.id}"
    Rails.logger.info "User signed in?: #{user_signed_in?}"
    Rails.logger.info "Current user: #{current_user&.id}"

    unless user_signed_in?
      Rails.logger.info "Forcing sign in for user: #{resource.id}"
      sign_in(resource)
      Rails.logger.info "Sign in completed. Current user: #{current_user&.id}"
    end

    session.delete(:pending_user_id)

    if passkey_available?
      new_user_passkey_path(first_time: true)  # ⭐ 正しいパス名に修正
    else
      root_path
    end
  end

  def passkey_available?
    true
  end
end