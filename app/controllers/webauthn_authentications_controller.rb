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
    Rails.logger.info "WebAuthn authentication attempt"
    Rails.logger.info "Params: #{params.inspect}"

    begin
      # セッションからチャレンジとメールアドレスを取得
      challenge = session[:authentication_challenge]
      email = session[:webauthn_email]

      Rails.logger.info "Challenge: #{challenge}, Email: #{email}"

      if challenge.blank? || email.blank?
        Rails.logger.error "Missing challenge or email in session"
        render json: { error: "認証セッションが無効です。再度ログインを試してください。" }, status: :bad_request
        return
      end

      user = User.find_by(email: email)
      if user.nil?
        Rails.logger.error "User not found: #{email}"
        render json: { error: "ユーザーが見つかりません。" }, status: :not_found
        return
      end

      # WebAuthn認証データを取得
      credential_params = params.require(:credential)
      Rails.logger.info "Credential params: #{credential_params.inspect}"

      # WebAuthn認証情報を構築
      webauthn_credential = WebAuthn::Credential.from_get({
                                                            id: credential_params[:id],
                                                            rawId: credential_params[:rawId],
                                                            type: credential_params[:type],
                                                            response: {
                                                              clientDataJSON: credential_params[:response][:clientDataJSON],
                                                              authenticatorData: credential_params[:response][:authenticatorData],
                                                              signature: credential_params[:response][:signature],
                                                              userHandle: credential_params[:response][:userHandle]
                                                            }
                                                          })

      Rails.logger.info "WebAuthn credential constructed"

      # データベースから対応する認証情報を検索
      stored_credential = user.webauthn_credentials.find_by(external_id: credential_params[:id])

      if stored_credential.nil?
        Rails.logger.error "Stored credential not found for ID: #{credential_params[:id]}"
        render json: { error: "認証情報が見つかりません。" }, status: :not_found
        return
      end

      Rails.logger.info "Found stored credential: #{stored_credential.inspect}"

      # WebAuthn認証を検証
      begin
        webauthn_credential.verify(
          challenge,
          public_key: stored_credential.public_key,
          sign_count: stored_credential.sign_count
        )

        Rails.logger.info "WebAuthn verification successful"

        # サインカウントを更新
        stored_credential.update!(sign_count: webauthn_credential.sign_count)

        # 認証成功 - ユーザーをログイン
        sign_in(user)
        Rails.logger.info "User signed in successfully: #{user.email}"

        # セッションをクリア
        session.delete(:authentication_challenge)
        session.delete(:webauthn_email)

        render json: {
          success: true,
          message: "認証に成功しました。",
          redirect_url: root_path
        }

      rescue WebAuthn::Error => e
        Rails.logger.error "WebAuthn verification failed: #{e.message}"
        Rails.logger.error e.backtrace.join("\n")

        render json: {
          error: "WebAuthn認証に失敗しました: #{e.message}"
        }, status: :unauthorized

      end

    rescue => e
      Rails.logger.error "WebAuthn authentication error: #{e.message}"
      Rails.logger.error e.backtrace.join("\n")

      render json: {
        error: "認証処理中にエラーが発生しました: #{e.message}"
      }, status: :internal_server_error
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
