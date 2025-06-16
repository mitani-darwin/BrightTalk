class WebauthnAuthenticationsController < ApplicationController
  skip_before_action :authenticate_user!

  def new
    if user_signed_in?
      redirect_to root_path
      return
    end

    @email = params[:email]

    # AJAX リクエストの場合（メールアドレスによる認証方法の確認）
    if request.xhr? && @email.present?
      user = User.find_by(email: @email)

      if user
        # WebAuthn認証が有効な場合
        if user.webauthn_enabled? && user.has_webauthn_credentials?
          webauthn_options = WebAuthn::Credential.options_for_get(
            allow: user.webauthn_credentials.pluck(:external_id),
            rp_id: Rails.env.development? ? "localhost" : "yourdomain.com"
          )
          session[:authentication_challenge] = webauthn_options.challenge
          session[:user_id_for_authentication] = user.id

          render json: {
            webauthn_enabled: true,
            webauthn_options: webauthn_options,
            message: 'WebAuthn認証を使用してください'
          }
        else
          # パスワード認証を使用
          render json: {
            webauthn_enabled: false,
            message: 'パスワードを入力してください'
          }
        end
      else
        render json: {
          error: 'アカウントが存在しません。',
          user_exists: false
        }, status: :unprocessable_entity
      end
    end
  end

  def create
    user_id = session[:user_id_for_authentication]
    user = User.find(user_id) if user_id

    unless user
      redirect_to login_path, alert: '認証に失敗しました。'
      return
    end

    webauthn_credential = WebAuthn::Credential.from_get(credential_params)
    stored_credential = user.webauthn_credentials.find_by(external_id: webauthn_credential.id)

    unless stored_credential
      redirect_to login_path, alert: '認証に失敗しました。'
      return
    end

    begin
      webauthn_credential.verify(
        session[:authentication_challenge],
        public_key: stored_credential.public_key,
        sign_count: stored_credential.sign_count
      )

      stored_credential.update!(
        sign_count: webauthn_credential.sign_count,
        last_used_at: Time.current
      )

      sign_in(user)
      session.delete(:authentication_challenge)
      session.delete(:user_id_for_authentication)

      redirect_to root_path, notice: 'WebAuthn認証でログインしました。'
    rescue WebAuthn::Error => e
      Rails.logger.error "WebAuthn authentication failed: #{e.message}"
      redirect_to login_path, alert: '認証に失敗しました。'
    end
  end

  # パスワード認証処理を追加
  def password_login
    email = params[:email]
    password = params[:password]

    user = User.find_by(email: email)

    if user && user.valid_password?(password) && !user.webauthn_enabled?
      sign_in(user)
      redirect_to root_path, notice: 'ログインしました。'
    else
      redirect_to login_path, alert: 'メールアドレスまたはパスワードが正しくありません。'
    end
  end

  private

  def credential_params
    params.require(:credential).permit(:id, :rawId, :type, :response => [:clientDataJSON, :authenticatorData, :signature, :userHandle])
  end
end