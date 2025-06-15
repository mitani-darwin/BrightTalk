class ApplicationController < ActionController::Base
  before_action :authenticate_user!
  before_action :configure_permitted_parameters, if: :devise_controller?

  protected

  def configure_permitted_parameters
    devise_parameter_sanitizer.permit(:sign_up, keys: [:name])
    devise_parameter_sanitizer.permit(:account_update, keys: [:name, :avatar])
  end

  # Deviseのセッション認証をオーバーライドしてWebAuthnにリダイレクト
  def authenticate_user!
    unless user_signed_in?
      redirect_to login_path
    end
  end

  # WebAuthn認証が必要なユーザーをチェック
  def ensure_webauthn_setup
    if user_signed_in? && current_user.webauthn_required?
      redirect_to new_webauthn_credential_path, alert: 'WebAuthn認証の設定が必要です。'
    end
  end
end