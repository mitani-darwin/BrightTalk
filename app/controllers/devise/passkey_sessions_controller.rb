class Devise::PasskeySessionsController < DeviseController
  prepend_before_action :allow_params_authentication!, only: [:new, :create]
  prepend_before_action :verify_signed_out_user, only: [:destroy]

  def new
    Rails.logger.info "Devise::PasskeySessions new action"
    @email = params[:email] || session[:passkey_email]
  end

  def challenge
    email = params[:email]
    Rails.logger.info "Passkey challenge for email: #{email}"

    if email.blank?
      render json: { error: "メールアドレスが必要です" }, status: :bad_request
      return
    end

    user = User.find_by(email: email)
    if user.nil?
      render json: { error: "このメールアドレスのユーザーは存在しません" }, status: :not_found
      return
    end

    session[:passkey_email] = email

    if user.passkeys.exists?
      # Passkey認証用のチャレンジを生成
      challenge = SecureRandom.urlsafe_base64(32)
      session[:passkey_authentication_challenge] = challenge

      passkey_options = {
        challenge: challenge,
        rpId: Rails.env.development? ? "localhost" : "www.brighttalk.jp",
        timeout: 300000,
        userVerification: "required",
        allowCredentials: user.passkeys.pluck(:identifier).map { |identifier|
          { type: "public-key", id: identifier }
        }
      }

      render json: {
        auth_method: "passkey",
        passkey_enabled: true,
        has_passkeys: true,
        passkey_options: passkey_options
      }
    else
      render json: {
        auth_method: "password",
        passkey_enabled: false,
        has_passkeys: false
      }
    end
  end

  def create
    Rails.logger.info "Passkey authentication attempt"

    begin
      challenge = session[:passkey_authentication_challenge]
      email = session[:passkey_email]

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

      credential_params = params.require(:credential)

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

      stored_passkey = user.passkeys.find_by(identifier: credential_params[:id])

      if stored_passkey.nil?
        Rails.logger.error "Stored passkey not found for ID: #{credential_params[:id]}"
        render json: { error: "認証情報が見つかりません。" }, status: :not_found
        return
      end

      # Passkey認証を検証
      webauthn_credential.verify(
        challenge,
        public_key: stored_passkey.public_key,
        sign_count: stored_passkey.sign_count
      )

      # サインカウントを更新
      stored_passkey.update!(
        sign_count: webauthn_credential.sign_count,
        last_used_at: Time.current
      )

      # ユーザーの確認状態をチェック
      unless user.confirmed?
        Rails.logger.info "User attempted sign-in but email not confirmed: #{user.email}"
        render json: {
          error: "メールアドレスが確認されていません。確認メールに記載されたリンクをクリックして、登録を完了してください。"
        }, status: :unauthorized
        return
      end

      # 認証成功 - ユーザーをログイン
      sign_in(user)
      Rails.logger.info "User signed in successfully: #{user.email}"

      # セッションをクリア
      session.delete(:passkey_authentication_challenge)
      session.delete(:passkey_email)

      render json: {
        success: true,
        message: "認証に成功しました。",
        redirect_url: after_sign_in_path_for(user)
      }

    rescue WebAuthn::Error => e
      Rails.logger.error "Passkey verification failed: #{e.message}"
      render json: {
        error: "パスキー認証に失敗しました: #{e.message}"
      }, status: :unauthorized
    rescue => e
      Rails.logger.error "Passkey authentication error: #{e.message}"
      render json: {
        error: "認証処理中にエラーが発生しました: #{e.message}"
      }, status: :internal_server_error
    end
  end

  private

  def allow_params_authentication!
    devise_parameter_sanitizer.permit(:sign_in, keys: [:email])
  end

  def verify_signed_out_user
    redirect_to root_path if user_signed_in?
  end
end