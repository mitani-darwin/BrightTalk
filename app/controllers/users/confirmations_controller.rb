# frozen_string_literal: true

class Users::ConfirmationsController < Devise::ConfirmationsController
  # GET /resource/confirmation?confirmation_token=abcdef
  def show
    self.resource = resource_class.confirm_by_token(params[:confirmation_token])
    yield resource if block_given?

    if resource.errors.empty?
      set_flash_message!(:notice, :confirmed)
      flash[:notice] = "メールアドレスが確認できました。ログインしてください。"
      respond_with_navigational(resource){ redirect_to after_confirmation_path_for(resource_name, resource) }
    else
      respond_with_navigational(resource.errors, status: :unprocessable_entity){ render :new }
    end
  end

  protected

  def after_confirmation_path_for(resource_name, resource)
    # 確認後はサインアウトしてログイン画面に遷移
    sign_out(resource) if resource
    new_user_session_path
  end
end