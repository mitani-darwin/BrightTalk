class ApplicationController < ActionController::Base
  # CSRF保護を有効にする
  protect_from_forgery with: :exception

  # 認証が必要なアクション（特定のコントローラー・アクションを除外）
  before_action :authenticate_user!, if: -> { !devise_controller? && !public_access_allowed? }

  # Deviseのパラメータ許可
  before_action :configure_permitted_parameters, if: :devise_controller?

  # デバッグ用ログ（開発環境のみ）
  before_action :log_user_status, if: -> { Rails.env.development? }

  private

  def log_user_status
    Rails.logger.info "=== User Status Debug ==="
    Rails.logger.info "Controller: #{self.class.name}##{action_name}"
    Rails.logger.info "Current user: #{current_user&.id}"
    Rails.logger.info "User signed in?: #{user_signed_in?}"
    Rails.logger.info "Session ID: #{session.id}"
    Rails.logger.info "=========================="
  end

  # 公開アクセスを許可するかどうかの判定 - Passkeyに更新
  def public_access_allowed?
    # ログインページ、新規登録ページ、Passkey関連ページ
    controller_name.in?([ "passkey_authentications", "passkeys", "sessions", "passkey_registrations" ]) ||
      # ユーザー関連のnew, create, registration_pendingアクション
      (controller_name == "users" && action_name.in?([ "new", "create", "registration_pending" ])) ||
      # 投稿の一覧・詳細は公開
      (controller_name == "posts" && action_name.in?([ "index", "show" ])) ||
      # ユーザーの詳細は公開
      (controller_name == "users" && action_name == "show") ||
      # 静的ページ（プライバシーポリシーなど）は公開
      (controller_name == "pages")
  end

  # Deviseのストロングパラメータ設定
  def configure_permitted_parameters
    devise_parameter_sanitizer.permit(:sign_up, keys: [ :name ])
    devise_parameter_sanitizer.permit(:account_update, keys: [ :name ])
  end

  # メール確認後のリダイレクト先をカスタマイズ - Passkeyに更新
  def after_confirmation_path_for(resource_name, resource)
    # ユーザーが既にPasskey認証を持っている場合はroot_pathに
    if resource.passkeys.exists?
      root_path
    else
      # Passkey設定ページにリダイレクト
      new_user_passkey_path
    end
  end

  # 新規登録後のリダイレクト先をカスタマイズ - Passkeyに更新
  def after_sign_up_path_for(resource)
    # 確認メール送信の場合は、確認待ちページに遷移
    if resource.pending_reconfirmation?
      users_registration_success_path
    else
      # Passkey設定ページにリダイレクト
      new_user_passkey_path
    end
  end
end
