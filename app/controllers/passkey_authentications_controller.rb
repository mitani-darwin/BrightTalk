class PasskeyAuthenticationsController < ApplicationController
  skip_before_action :authenticate_user!

  def new
    # パスキー認証画面（通常は/users/sign_inから来る）
    redirect_to new_user_session_path
  end

  def create
    Rails.logger.info "PasskeyAuthenticationsController#create called"

    begin
      credential_data = params[:credential]
      if credential_data.blank?
        render json: { error: "認証データが提供されていません" }, status: :unprocessable_content
        return
      end

      # WebAuthn認証データを検証
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

      # データベースから対応するパスキーを取得
      stored_credential = WebauthnCredential.find_by(external_id: credential_data[:id])

      if stored_credential.blank?
        Rails.logger.error "Stored credential not found for ID: #{credential_data[:id]}"
        render json: { error: "パスキーが見つかりません" }, status: :unauthorized
        return
      end

      # 認証チャレンジを取得
      challenge = session[:passkey_auth_challenge]
      if challenge.blank?
        Rails.logger.error "Authentication challenge not found in session"
        render json: { error: "認証セッションが無効です" }, status: :unauthorized
        return
      end

      # パスキー認証を検証
      webauthn_credential.verify(
        challenge,
        public_key: stored_credential.public_key,
        sign_count: stored_credential.sign_count
      )

      # サインカウントを更新
      stored_credential.update!(
        sign_count: webauthn_credential.sign_count,
        last_used_at: Time.current
      )

      # ユーザーをログインさせる
      user = stored_credential.user
      sign_in(user)

      # セッションをクリア
      session.delete(:passkey_auth_challenge)

      Rails.logger.info "Passkey authentication successful for user: #{user.id}"

      respond_to do |format|
        format.json {
          render json: {
            success: true,
            message: "ログインしました",
            redirect_url: after_sign_in_path_for(user)
          }
        }
        format.html { redirect_to after_sign_in_path_for(user), notice: "ログインしました" }
      end

    rescue WebAuthn::Error => e
      Rails.logger.error "Passkey authentication failed: #{e.message}"
      render json: { error: "パスキー認証に失敗しました: #{e.message}" }, status: :unauthorized
    rescue => e
      Rails.logger.error "Authentication error: #{e.message}"
      render json: { error: "認証処理中にエラーが発生しました" }, status: :internal_server_error
    end
  end

  def auth_options
    Rails.logger.info "Generating passkey authentication options"

    email = params[:email]
    if email.blank?
      render json: { error: "メールアドレスが必要です" }, status: :bad_request
      return
    end

    user = User.find_by(email: email)
    if user.blank?
      render json: { error: "ユーザーが見つかりません" }, status: :not_found
      return
    end

    if !user.has_passkeys?
      render json: { error: "このアカウントにはパスキーが登録されていません" }, status: :unprocessable_content
      return
    end

    # 認証チャレンジを生成
    challenge = SecureRandom.urlsafe_base64(32)
    session[:passkey_auth_challenge] = challenge

    # WebAuthn認証オプション
    auth_options = {
      challenge: challenge,
      timeout: 300000,
      rpId: Rails.env.development? ? "localhost" : "www.brighttalk.jp",
      userVerification: "required",
      authenticatorSelection: {
        authenticatorAttachment: "platform",
        userVerification: "required"
      },
      allowCredentials: user.passkeys.map { |passkey|
        {
          id: passkey.identifier,
          type: "public-key"
        }
      }
    }

    Rails.logger.info "Authentication options generated for user: #{user.id}"

    render json: {
      success: true,
      passkey_options: auth_options
    }
  end
end
