class ApplicationController < ActionController::Base
  # CSRF保護を有効にする
  protect_from_forgery with: :exception

  # 認証が必要なアクション（特定のコントローラー・アクションを除外）
  before_action :authenticate_user!, if: -> { !devise_controller? && !public_access_allowed? }

  # Deviseのパラメータ許可
  before_action :configure_permitted_parameters, if: :devise_controller?

  private

  # 公開アクセスを許可するかどうかの判定
  def public_access_allowed?
    # ログインページ、新規登録ページ、WebAuthn関連ページ
    controller_name.in?([ "webauthn_authentications", "webauthn_credentials", "sessions" ]) ||
      # ユーザー関連のnew, create, registration_pendingアクション
      (controller_name == "users" && action_name.in?([ "new", "create", "registration_pending" ])) ||
      # 投稿の一覧・詳細は公開
      (controller_name == "posts" && action_name.in?([ "index", "show" ])) ||
      # ユーザーの詳細は公開
      (controller_name == "users" && action_name == "show")
  end

  # Deviseのストロングパラメータ設定
  def configure_permitted_parameters
    devise_parameter_sanitizer.permit(:sign_up, keys: [ :name ])
    devise_parameter_sanitizer.permit(:account_update, keys: [ :name ])
  end

  # メール確認後のリダイレクト先をカスタマイズ
  def after_confirmation_path_for(resource_name, resource)
    # ユーザーが既にWebAuthn認証を持っている場合はroot_pathに
    if resource.has_webauthn_credentials?
      root_path
    else
      # WebAuthn設定ページにリダイレクト
      new_webauthn_credential_path
    end
  end

  # 新規登録後のリダイレクト先をカスタマイズ
  def after_sign_up_path_for(resource)
    # 確認メール送信の場合は、確認待ちページに遷移
    if resource.pending_reconfirmation?
      users_registration_success_path
    else
      # WebAuthn設定ページにリダイレクト
      new_webauthn_credential_path
    end
  end
end