class WebauthnCredentialsController < ApplicationController
  before_action :authenticate_user!

  def new
    # WebAuthnオプションを生成
    @options = WebAuthn::Credential.options_for_create(
      user: {
        id: current_user.webauthn_id,
        name: current_user.email,
        display_name: current_user.email
      },
      exclude: current_user.webauthn_credentials.pluck(:external_id),
      rp: {
        name: "BrightTalk",
        id: webauthn_rp_id
      }
    )

    # セッションにチャレンジを保存
    session[:webauthn_challenge] = @options.challenge

    # デバッグ用ログ
    Rails.logger.info "WebAuthn options generated: #{@options.as_json}"
  end

  def create
    webauthn_credential = WebAuthn::Credential.from_create(credential_params)

    begin
      webauthn_credential.verify(
        session[:webauthn_challenge],
        origin: request_origin,
        rp_id: webauthn_rp_id
      )

      current_user.webauthn_credentials.create!(
        external_id: webauthn_credential.id,
        public_key: webauthn_credential.public_key,
        sign_count: webauthn_credential.sign_count,
        name: params[:name] || 'メインデバイス'
      )

      session.delete(:webauthn_challenge)

      render json: {
        success: true,
        redirect_url: webauthn_credentials_path
      }

    rescue => e
      Rails.logger.error "WebAuthn Error: #{e.message}"
      Rails.logger.error "Backtrace: #{e.backtrace.first(5).join("\n")}"

      render json: {
        success: false,
        error: "WebAuthn認証の設定に失敗しました: #{e.message}"
      }, status: :unprocessable_entity
    end
  end

  private

  def credential_params
    params.require(:credential).permit(:id, :rawId, :type, response: [:clientDataJSON, :attestationObject])
  end

  def request_origin
    if Rails.env.production?
      "https://www.brighttalk.jp"
    else
      "http://localhost:3000"
    end
  end

  def webauthn_rp_id
    if Rails.env.production?
      "www.brighttalk.jp"
    else
      "localhost"
    end
  end
end