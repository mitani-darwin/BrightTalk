class ApplicationController < ActionController::Base
  # Rails 8対応のCSRF保護設定
  protect_from_forgery with: :exception, prepend: true

  # ActiveStorageエンドポイントのみCSRFチェックをスキップ
  skip_before_action :verify_authenticity_token, if: -> {
    request.path.start_with?('/rails/active_storage/')
  }

  # 認証が必要なアクション（特定のコントローラー・アクションを除外）
  before_action :authenticate_user!, if: -> { !devise_controller? && !public_access_allowed? }

  # Deviseのパラメータ許可
  before_action :configure_permitted_parameters, if: :devise_controller?

  # デバッグ用ログ（開発環境のみ）
  before_action :log_csrf_info, if: -> { Rails.env.development? }

  # Rails 8では、以下の設定を追加
  before_action :set_csrf_cookie, if: -> { protect_against_forgery? }


  before_action :handle_csrf_verification, if: -> { request.post? && !Rails.env.test? }

  private

  def log_upload_attempts
    Rails.logger.info "=== Upload Debug ==="
    Rails.logger.info "Request method: #{request.method}"
    Rails.logger.info "Content-Type: #{request.content_type}"
    Rails.logger.info "File params present: #{params.dig(:post, :videos).present?}"
    Rails.logger.info "==================="
  end

  def log_user_status
    Rails.logger.info "=== User Status Debug ==="
    Rails.logger.info "Controller: #{self.class.name}##{action_name}"
    Rails.logger.info "Current user: #{current_user&.id}"
    Rails.logger.info "User signed in?: #{user_signed_in?}"
    Rails.logger.info "Session ID: #{session.id}"
    Rails.logger.info "=========================="
  end

  def set_csrf_cookie
    cookies["CSRF-TOKEN"] = {
      value: form_authenticity_token,
      secure: Rails.env.production?,
      same_site: :lax
    }
  end

  def log_csrf_info
    Rails.logger.info "=== CSRF Debug ==="
    Rails.logger.info "Session ID: #{session.id}"
    Rails.logger.info "CSRF Token from session: #{session[:_csrf_token]}"
    Rails.logger.info "CSRF Token from params: #{params[:authenticity_token]}"
    Rails.logger.info "CSRF Token from header: #{request.headers['X-CSRF-Token']}"
    Rails.logger.info "==================="
  end

  # Rails 8 + Devise 4.9.4 互換性対応
  def handle_csrf_verification
    # POSTリクエストでCSRFトークンが不足している場合の対応
    if request.post? && params[:authenticity_token].blank? && request.headers['X-CSRF-Token'].blank?
      Rails.logger.warn "=== CSRF Token Missing - Rails 8 Compatibility Fix ==="
      Rails.logger.warn "Controller: #{controller_name}##{action_name}"
      Rails.logger.warn "Session CSRF Token: #{session[:_csrf_token]}"

      # セッションからCSRFトークンを取得してパラメータに設定
      if session[:_csrf_token].present?
        params[:authenticity_token] = session[:_csrf_token]
        Rails.logger.warn "Applied session CSRF token to params"
      end
      Rails.logger.warn "=================================================="
    end
  end

  # 公開アクセスを許可するかどうかの判定
  def public_access_allowed?
    controller_name.in?(["passkey_authentications", "passkeys", "sessions", "passkey_registrations"]) ||
      (controller_name == "users" && action_name.in?(["new", "create", "registration_pending"])) ||
      (controller_name == "posts" && action_name.in?(["index", "show"])) ||
      (controller_name == "users" && action_name == "show") ||
      (controller_name == "pages")
  end

  # Deviseのストロングパラメータ設定
  def configure_permitted_parameters
    devise_parameter_sanitizer.permit(:sign_up, keys: [:name])
    devise_parameter_sanitizer.permit(:account_update, keys: [:name])
  end

  # メール確認後のリダイレクト先をカスタマイズ
  def after_confirmation_path_for(resource_name, resource)
    # ユーザーが既にPasskey認証を持っている場合はroot_pathに
    if resource.passkeys.exists?
      root_path
    else
      # Passkey設定ページにリダイレクト
      new_user_passkey_path
    end
  end

  # 新規登録後のリダイレクト先をカスタマイズ
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