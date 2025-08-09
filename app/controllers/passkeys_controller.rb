
class PasskeyAuthenticationsController < ApplicationController
  skip_before_action :authenticate_user!

  def new
    Rails.logger.info "Passkey authentication: showing unified login form"
    @email = params[:email] || session[:passkey_email]
  end

  def check_login_method
    email = params[:email]
    Rails.logger.info "check_login_method called with email: #{email}"

    if email.blank?
      Rails.logger.warn "check_login_method: email is blank"
      respond_to do |format|
        format.json { render json: { error: "メールアドレスが必要です" }, status: :bad_request }
        format.html { redirect_to new_passkey_authentication_path, alert: "メールアドレスを入力してください" }
      end
      return
    end

    user = User.find_by(email: email)
    Rails.logger.info "check_login_method: user found: #{user.present?}"

    if user.nil?
      Rails.logger.warn "check_login_method: user not found for email: #{email}"
      respond_to do |format|
        format.json { render json: { error: "このメールアドレスのユーザーは存在しません" }, status: :not_found }
        format.html { redirect_to new_passkey_authentication_path, alert: "このメールアドレスのユーザーは存在しません" }
      end
      return
    end

    # セッションにメールアドレスを保存
    session[:passkey_email] = email

    Rails.logger.info "check_login_method: has_passkeys=#{user.passkeys.exists?}"

    # Passkey認証が利用可能かどうかを判定
    if user.passkeys.exists?
      # Passkey認証を使用
      user_passkeys = user.passkeys.pluck(:identifier)

      if user_passkeys.empty?
        Rails.logger.warn "check_login_method: No passkeys found"
        respond_to do |format|
          format.json { render json: { error: "パスキー認証情報が登録されていません" }, status: :unprocessable_entity }
          format.html { redirect_to new_passkey_authentication_path, alert: "パスキー認証情報が登録されていません" }
        end
        return
      end

      # Passkey認証用のチャレンジを生成
      challenge = SecureRandom.urlsafe_base64(32)
      session[:passkey_authentication_challenge] = challenge

      passkey_options = {
        challenge: challenge,
        rpId: Rails.env.development? ? "localhost" : "www.brighttalk.jp",
        timeout: 300000,
        userVerification: "required",
        allowCredentials: user_passkeys.map { |identifier|
          { type: "public-key", id: identifier }
        }
      }

      Rails.logger.info "Generated Passkey options for user: #{user.id}"

      respond_to do |format|
        format.json {
          render json: {
            auth_method: "passkey",
            passkey_enabled: true,
            has_passkeys: true,
            passkey_options: passkey_options
          }
        }
        format.html {
          @passkey_options = passkey_options
          @email = email
          render :passkey_login
        }
      end
    else
      # パスワード認証を使用
      Rails.logger.info "Using password authentication for user: #{user.id}"

      respond_to do |format|
        format.json {
          render json: {
            auth_method: "password",
            passkey_enabled: false,
            has_passkeys: false
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
    Rails.logger.info "Passkey authentication attempt"
    Rails.logger.info "Params: #{params.inspect}"

    begin
      # セッションからチャレンジとメールアドレスを取得
      challenge = session[:passkey_authentication_challenge]
      email = session[:passkey_email]

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

      # Passkey認証データを取得
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

      Rails.logger.info "Passkey credential constructed"

      # データベースから対応する認証情報を検索
      stored_passkey = user.passkeys.find_by(identifier: credential_params[:id])

      if stored_passkey.nil?
        Rails.logger.error "Stored passkey not found for ID: #{credential_params[:id]}"
        render json: { error: "認証情報が見つかりません。" }, status: :not_found
        return
      end

      Rails.logger.info "Found stored passkey: #{stored_passkey.inspect}"

      # Passkey認証を検証
      begin
        webauthn_credential.verify(
          challenge,
          public_key: stored_passkey.public_key,
          sign_count: stored_passkey.sign_count
        )

        Rails.logger.info "Passkey verification successful"

        # サインカウントを更新
        stored_passkey.update!(
          sign_count: webauthn_credential.sign_count,
          last_used_at: Time.current
        )

        # 認証成功 - ユーザーをログイン
        sign_in(user)
        Rails.logger.info "User signed in successfully: #{user.email}"

        # セッションをクリア
        session.delete(:passkey_authentication_challenge)
        session.delete(:passkey_email)

        render json: {
          success: true,
          message: "認証に成功しました。",
          redirect_url: root_path
        }

      rescue WebAuthn::Error => e
        Rails.logger.error "Passkey verification failed: #{e.message}"
        render json: {
          error: "パスキー認証に失敗しました: #{e.message}"
        }, status: :unauthorized
      end

    rescue => e
      Rails.logger.error "Passkey authentication error: #{e.message}"
      render json: {
        error: "認証処理中にエラーが発生しました: #{e.message}"
      }, status: :internal_server_error
    end
  end

  def password_login
    Rails.logger.info "PasskeyAuthenticationsController#password_login called"
    email = params[:email] || session[:passkey_email]
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
      session.delete(:passkey_email)
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