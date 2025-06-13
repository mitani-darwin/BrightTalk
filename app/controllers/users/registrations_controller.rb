
# frozen_string_literal: true

class Users::RegistrationsController < Devise::RegistrationsController
  # GET /users/sign_up
  def new
    if session[:registration_success_message]
      flash.now[:notice] = session[:registration_success_message]
      session.delete(:registration_success_message)
    end
    super
  end

  # POST /users
  def create
    super do |resource|
      if resource.persisted? && !resource.active_for_authentication?
        # Deviseのデフォルトメッセージはそのまま使用
        # flash.clear を削除
        # セッションにメッセージを保存して、リダイレクト後に表示
        session[:registration_success_message] = flash[:notice]
        flash.clear # リダイレクト前にクリア
      end
    end
  end

  protected

  def after_sign_up_path_for(resource)
    sign_out(resource)
    new_user_registration_path
  end

  def after_inactive_sign_up_path_for(resource)
    new_user_registration_path
  end

  # これらのメソッドは不要なので削除
  # def set_flash_message(key, kind, options = {})
  #   return if kind == :signed_up_but_unconfirmed
  #   super
  # end

  # def set_flash_message!(key, kind, options = {})
  #   return if kind == :signed_up_but_unconfirmed
  #   super
  # end
end