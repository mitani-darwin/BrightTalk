class Users::RegistrationsController < Devise::RegistrationsController
  before_action :configure_sign_up_params, only: [ :create ]
  before_action :configure_account_update_params, only: [ :update ]

  # GET /resource/sign_up
  def new
    super
  end

  # POST /resource
  def create
    super
  end

  # GET /resource/edit
  def edit
    super
  end

  # PUT /resource
  def update
    super
  end

  # GET /resource/cancel
  def cancel
    super
  end

  protected

  # サインアップ後のリダイレクト先
  def after_sign_up_path_for(resource)
    # メール確認が必要な場合は確認待ちページへ
    if resource.persisted? && !resource.confirmed?
      registration_pending_users_path
    else
      root_path
    end
  end

  # アカウント更新後のリダイレクト先
  def after_update_path_for(resource)
    user_account_path
  end

  private

  def configure_sign_up_params
    devise_parameter_sanitizer.permit(:sign_up, keys: [ :name ])
  end

  def configure_account_update_params
    devise_parameter_sanitizer.permit(:account_update, keys: [ :name ])
  end
end
