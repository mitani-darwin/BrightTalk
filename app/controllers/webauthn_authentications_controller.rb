class WebauthnAuthenticationsController < ApplicationController
  # ApplicationControllerの public_access_allowed? メソッドで制御されるため
  # skip_before_action は不要

  def new
    # 統合ログイン画面を表示
    # メールアドレス入力フォームを表示
    Rails.logger.info "WebAuthn authentication: showing unified login form"
    @email = params[:email] || session[:webauthn_email]
  end

  def check_login_method
    # メールアドレスを受け取って認証方法を判定するアクション
    email = params[:email]
    Rails.logger.info "check_login_method called with email: #{email}"

    if email.blank?
      Rails.logger.warn "check_login_method: email is blank"
      respond_to do |format|
        format.json { render json: { error: "メールアドレスが必要です" }, status: :bad_request }
        format.html { redirect_to new_webauthn_authentication_path, alert: "メールアドレスを入力してください" }
      end
      return
    end

    user = User.find_by(email: email)
    Rails.logger.info "check_login_method: user found: #{user.present?}"

    if user.nil?
      Rails.logger.warn "check_login_method: user not found for email: #{email}"
      respond_to do |format|
        format.json { render json: { error: "このメールアドレスのユーザーは存在しません" }, status: :not_found }
        format.html { redirect_to new_webauthn_authentication_path, alert: "このメールアドレスのユーザーは存在しません" }
      end
      return
    end

    # セッションにメールアドレスを保存
    session[:webauthn_email] = email

    Rails.logger.info "check_login_method: webauthn_enabled=#{user.webauthn_enabled}, has_credentials=#{user.has_webauthn_credentials?}"

    # WebAuthn認証が有効かどうかを判定
    if user.webauthn_enabled?
      # WebAuthn認証を使用
      user_credentials = user.webauthn_credentials.pluck(:external_id)

      if user_credentials.empty?
        Rails.logger.warn "check_login_method: WebAuthn enabled but no credentials found"
        respond_to do |format|
          format.json { render json: { error: "WebAuthn認証情報が登録されていません" }, status: :unprocessable_entity }
          format.html { redirect_to new_webauthn_authentication_path, alert: "WebAuthn認証情報が登録されていません" }
        end
        return
      end

      # WebAuthn認証用のオプションを生成
      allow_credentials = user_credentials.map { |cred_id|
        {
          id: cred_id,
          type: "public-key"
        }
      }

      webauthn_options = WebAuthn::Credential.options_for_get(
        allow: allow_credentials
      )

      # セッションにチャレンジを保存
      session[:authentication_challenge] = webauthn_options.challenge

      Rails.logger.info "Generated WebAuthn options for user: #{user.id}"

      respond_to do |format|
        format.json {
          render json: {
            auth_method: "webauthn",
            webauthn_enabled: true,
            has_webauthn_credentials: true,
            webauthn_options: webauthn_options
          }
        }
        format.html {
          @webauthn_options = webauthn_options
          @email = email
          render :webauthn_login
        }
      end
    else
      # パスワード認証を使用
      Rails.logger.info "Using password authentication for user: #{user.id}"

      respond_to do |format|
        format.json {
          render json: {
            auth_method: "password",
            webauthn_enabled: false,
            has_webauthn_credentials: user.has_webauthn_credentials?
          }
        }
        format.html {
          @email = email
          render :password_login
        }
      end
    end
  end

  def create
    Rails.logger.info "WebauthnAuthenticationsController#create called"
    Rails.logger.info "Params: #{params.inspect}"
    Rails.logger.info "Session keys: #{session.keys}"

    begin
      # セッションからチャレンジとメールアドレスを取得
      stored_challenge = session[:authentication_challenge]
      email = session[:webauthn_email]

      Rails.logger.info "Stored challenge: #{stored_challenge&.present? ? 'present' : 'missing'}"
      Rails.logger.info "Email from session: #{email}"

      if stored_challenge.blank?
        error_message = "認証チャレンジが見つかりません。再度お試しください。"
        Rails.logger.error "Authentication challenge not found in session"

        respond_to do |format|
          format.html { redirect_to new_webauthn_authentication_path, alert: error_message }
          format.json { render json: { error: error_message }, status: :unprocessable_entity }
        end
        return
      end

      if email.blank?
        error_message = "メールアドレスが見つかりません。再度ログインしてください。"
        Rails.logger.error "Email not found in session"

        respond_to do |format|
          format.html { redirect_to new_webauthn_authentication_path, alert: error_message }
          format.json { render json: { error: error_message }, status: :unprocessable_entity }
        end
        return
      end

      user = User.find_by(email: email)
      if user.nil?
        error_message = "ユーザーが見つかりませんでした。"
        Rails.logger.error "User not found for email: #{email}"

        respond_to do |format|
          format.html { redirect_to new_webauthn_authentication_path, alert: error_message }
          format.json { render json: { error: error_message }, status: :unprocessable_entity }
        end
        return
      end

      # WebAuthn認証データの取得
      credential_data = params[:credential]
      if credential_data.blank?
        error_message = "認証データが提供されていません"
        Rails.logger.error "Credential data is blank"

        respond_to do |format|
          format.html { redirect_to new_webauthn_authentication_path, alert: error_message }
          format.json { render json: { error: error_message }, status: :unprocessable_entity }
        end
        return
      end

      Rails.logger.info "Processing WebAuthn authentication for user: #{user.id}"
      Rails.logger.info "Credential ID: #{credential_data[:id]}"

      # WebAuthn認証情報を検証
      webauthn_credential = WebAuthn::Credential.from_get({
                                                            "type" => credential_data[:type],
                                                            "id" => credential_data[:id],
                                                            "rawId" => credential_data[:rawId],
                                                            "response" => {
                                                              "clientDataJSON" => credential_data[:response][:clientDataJSON],
                                                              "authenticatorData" => credential_data[:response][:authenticatorData],
                                                              "signature" => credential_data[:response][:signature],
                                                              "userHandle" => credential_data[:response][:userHandle]
                                                            }
                                                          })

      # データベースから対応する認証情報を取得
      stored_credential = user.webauthn_credentials.find_by(external_id: webauthn_credential.id)
      if stored_credential.nil?
        error_message = "認証情報が見つかりませんでした"
        Rails.logger.error "Stored credential not found for credential ID: #{webauthn_credential.id}"

        respond_to do |format|
          format.html { redirect_to new_webauthn_authentication_path, alert: error_message }
          format.json { render json: { error: error_message }, status: :unprocessable_entity }
        end
        return
      end

      # 認証を検証
      webauthn_credential.verify(
        stored_challenge.to_s,
        public_key: stored_credential.public_key,
        sign_count: stored_credential.sign_count
      )

      Rails.logger.info "WebAuthn authentication successful for user: #{user.id}"

      # サインカウントを更新
      stored_credential.update!(sign_count: webauthn_credential.sign_count, last_used_at: Time.current)

      # セッションをクリア
      session.delete(:authentication_challenge)
      session.delete(:webauthn_email)

      # ユーザーをログインさせる
      sign_in(user)

      Rails.logger.info "User signed in successfully: #{user.id}"

      # Safariでのリダイレクト対応
      respond_to do |format|
        format.html { redirect_to root_path, notice: "パスキー認証でログインしました" }
        format.json { render json: { success: true, redirect_url: root_path, message: "パスキー認証でログインしました" } }
      end

    rescue WebAuthn::Error => e
      Rails.logger.error "WebAuthn authentication failed: #{e.message}"
      Rails.logger.error "WebAuthn authentication backtrace: #{e.backtrace.join("\n")}"

      error_message = "パスキー認証に失敗しました: #{e.message}"

      respond_to do |format|
        format.html { redirect_to new_webauthn_authentication_path, alert: error_message }
        format.json { render json: { error: error_message }, status: :unprocessable_entity }
      end
    rescue StandardError => e
      Rails.logger.error "Unexpected error during WebAuthn authentication: #{e.message}"
      Rails.logger.error "Backtrace: #{e.backtrace.join("\n")}"

      error_message = "パスキー認証中に予期しないエラーが発生しました。"

      respond_to do |format|
        format.html { redirect_to new_webauthn_authentication_path, alert: error_message }
        format.json { render json: { error: error_message }, status: :internal_server_error }
      end
    end
  end

  def password_login
    Rails.logger.info "WebauthnAuthenticationsController#password_login called"
    Rails.logger.info "Params: #{params.inspect}"

    email = params[:email] || session[:webauthn_email]
    password = params[:password]

    if email.blank? || password.blank?
      respond_to do |format|
        format.html {
          flash.now[:alert] = "メールアドレスとパスワードを入力してください。"
          @email = email
          render :password_login
        }
        format.json { render json: { error: "メールアドレスとパスワードを入力してください。" }, status: :bad_request }
      end
      return
    end

    user = User.find_by(email: email)

    if user && user.valid_password?(password)
      # パスワード認証成功
      sign_in(user)
      session.delete(:webauthn_email)  # セッションをクリア
      Rails.logger.info "Password login successful for user: #{user.id}"

      respond_to do |format|
        format.html { redirect_to root_path, notice: "ログインしました" }
        format.json { render json: { success: true, redirect_url: root_path, message: "ログインしました" } }
      end
    else
      # パスワード認証失敗
      Rails.logger.warn "Password login failed for email: #{email}"

      respond_to do |format|
        format.html {
          flash.now[:alert] = "メールアドレスまたはパスワードが正しくありません。"
          @email = email
          render :password_login
        }
        format.json { render json: { error: "メールアドレスまたはパスワードが正しくありません。" }, status: :unauthorized }
      end
    end
  end
end
