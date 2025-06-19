
class SessionsController < Devise::SessionsController
  # WebAuthn確認用のアクション
  def check_webauthn
    email = params[:email]
    Rails.logger.info "check_webauthn called with email: #{email}"

    if email.blank?
      Rails.logger.warn "check_webauthn: email is blank"
      render json: { error: 'メールアドレスが必要です' }, status: :bad_request
      return
    end

    user = User.find_by(email: email)
    Rails.logger.info "check_webauthn: user found: #{user.present?}"

    if user.nil?
      Rails.logger.warn "check_webauthn: user not found for email: #{email}"
      render json: { error: 'このメールアドレスのユーザーは存在しません' }, status: :not_found
      return
    end

    # WebAuthn認証が必要かどうかを正しく判定
    webauthn_required = user.webauthn_required?
    has_credentials = user.has_webauthn_credentials?

    Rails.logger.info "check_webauthn: webauthn_enabled=#{user.webauthn_enabled}, has_credentials=#{has_credentials}, webauthn_required=#{webauthn_required}"

    render json: {
      webauthn_enabled: webauthn_required,
      has_webauthn_credentials: has_credentials
    }
  end

  def new
    # フラッシュメッセージをクリア（初期表示時のエラーを防ぐ）
    if request.referer.nil? || !request.referer.include?('/webauthn_authentications')
      flash.clear
    end

    # JSONリクエストの場合はエラーレスポンスを返す
    respond_to do |format|
      format.html { super }
      format.json do
        Rails.logger.warn "JSON request to login page - this should use check_webauthn endpoint"
        render json: {
          error: 'このエンドポイントはJSONリクエストに対応していません。/check_webauthnを使用してください。'
        }, status: :unprocessable_entity
      end
    end
  end

  def create
    Rails.logger.info "SessionsController#create called with params: #{params[:user]}"

    # 通常のパスワード認証処理
    self.resource = warden.authenticate!(auth_options)
    set_flash_message!(:notice, :signed_in)
    sign_in(resource_name, resource)
    yield resource if block_given?
    respond_with resource, location: after_sign_in_path_for(resource)
  rescue => e
    Rails.logger.error "Login error: #{e.message}"
    Rails.logger.error e.backtrace.join("\n")

    # エラーの場合はログイン画面に戻る
    flash.now[:alert] = 'メールアドレスまたはパスワードが正しくありません。'
    self.resource = resource_class.new(sign_in_params)
    render :new, status: :unprocessable_entity
  end


  private

  def after_sign_in_path_for(resource)
    root_path
  end

  def after_sign_out_path_for(resource_or_scope)
    new_user_session_path
  end
end