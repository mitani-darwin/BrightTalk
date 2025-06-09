
class ApplicationController < ActionController::Base
  # CSRF保護
  protect_from_forgery with: :exception

  # Deviseコントローラーでは認証をスキップ
  before_action :authenticate_user!, unless: :devise_controller?

  # Deviseのパラメータ許可
  before_action :configure_permitted_parameters, if: :devise_controller?

  private

  def configure_permitted_parameters
    devise_parameter_sanitizer.permit(:sign_up, keys: [:name])
    devise_parameter_sanitizer.permit(:account_update, keys: [:name])
  end
end