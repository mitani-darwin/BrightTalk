class SessionsController < Devise::SessionsController
  # WebAuthn確認用のアクション
  def check_webauthn
    email = params[:email]
    Rails.logger.info "check_webauthn called with email: #{email}"

    if email.blank?
      Rails.logger.warn "check_webauthn: email is blank"
      render json: { error: "メールアドレスが必要です" }, status: :bad_request
      return
    end

    user = User.find_by(email: email)
    Rails.logger.info "check_webauthn: user found: #{user.present?}"

    if user.nil?
      Rails.logger.warn "check_webauthn: user not found for email: #{email}"
      render json: { error: "このメールアドレスのユーザーは存在しません" }, status: :not_found
      return
    end

    # WebAuthn認証が必要かどうかを正しく判定
    webauthn_required = user.webauthn_required?
    has_credentials = user.has_webauthn_credentials?

    Rails.logger.info "check_webauthn: webauthn_enabled=#{user.webauthn_enabled}, has_credentials=#{has_credentials}, webauthn_required=#{webauthn_required}"

    if webauthn_required && has_credentials
      # WebAuthn認証用のオプションを生成（修正版）
      user_credentials = user.webauthn_credentials.pluck(:external_id)

      # allowCredentialsの形式を正しく設定
      allow_credentials = user_credentials.map { |cred_id|
        {
          id: cred_id,  # 文字列のまま渡す
          type: "public-key"
        }
      }

      webauthn_options = WebAuthn::Credential.options_for_get(
        allow: allow_credentials
      )

      # セッションにチャレンジとメールアドレスを保存
      session[:authentication_challenge] = webauthn_options.challenge
      session[:webauthn_email] = email

      Rails.logger.info "Generated WebAuthn options: #{webauthn_options.inspect}"
      Rails.logger.info "Allow credentials: #{allow_credentials.inspect}"

      render json: {
        webauthn_enabled: true,
        has_webauthn_credentials: true,
        webauthn_options: webauthn_options
      }
    else
      render json: {
        webauthn_enabled: false,
        has_webauthn_credentials: has_credentials
      }
    end
  end

  def new
    # フラッシュメッセージをクリア（初期表示時のエラーを防ぐ）
    if request.referer.nil? || !request.referer.include?("/webauthn_authentications")
      flash.clear
    end

    # JSONリクエストの場合はエラーレスポンスを返す
    respond_to do |format|
      format.html { super }
      format.json do
        Rails.logger.warn "JSON request to login page - this should use check_webauthn endpoint"
        render json: {
          error: "このエンドポイントはJSONリクエストに対応していません。/check_webauthnを使用してください。"
        }, status: :unprocessable_entity
      end
    end
  end

  def create
    Rails.logger.info "SessionsController#create called"
    Rails.logger.info "Params: #{params.inspect}"
    Rails.logger.info "User params: #{params[:user]}"

    # パラメータの検証
    if params[:user].blank?
      Rails.logger.warn "User params are blank"
      flash.now[:alert] = "メールアドレスとパスワードを入力してください。"
      self.resource = resource_class.new
      render :new, status: :unprocessable_entity
      return
    end

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
    flash.now[:alert] = "メールアドレスまたはパスワードが正しくありません。"
    # sign_in_paramsを安全に呼び出し
    safe_params = params[:user].present? ? sign_in_params : {}
    self.resource = resource_class.new(safe_params)
    render :new, status: :unprocessable_entity
  end

  private

  def after_sign_in_path_for(resource)
    root_path
  end

  def after_sign_out_path_for(resource_or_scope)
    root_path  # ログアウト後はトップページに遷移
  end

  def sign_in_params
    # パラメータが存在するかチェック
    if params[:user].present?
      params.require(:user).permit(:email, :password, :remember_me)
    else
      {}
    end
  end
end
