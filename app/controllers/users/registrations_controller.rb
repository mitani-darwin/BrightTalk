
# frozen_string_literal: true

class Users::RegistrationsController < Devise::RegistrationsController
  # GET /users/sign_up
  def new
    super
  end

  # POST /users
  def create
    # パスワードを自動生成
    generated_password = SecureRandom.alphanumeric(12)
    params[:user][:password] = generated_password
    params[:user][:password_confirmation] = generated_password

    super do |resource|
      if resource.persisted? && !resource.active_for_authentication?
        # 仮登録成功時は専用ページにリダイレクト
        sign_out(resource) if user_signed_in?
        redirect_to success_users_registration_path and return
      end
    end
  end

  # GET /users/registration/success
  def success
    # 成功ページを表示
  end

  protected

  def after_sign_up_path_for(resource)
    # この処理は上記のcreateメソッドで処理するため不要
    root_path
  end

  def after_inactive_sign_up_path_for(resource)
    # この処理は上記のcreateメソッドで処理するため不要
    root_path
  end

  # 自動生成されたパスワードも含めて許可
  def sign_up_params
    params.require(:user).permit(:name, :email, :password, :password_confirmation)
  end
end