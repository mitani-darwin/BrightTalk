class WebauthnCredentialsController < ApplicationController
  before_action :authenticate_user!

  def new
    @options = WebAuthn::Credential.options_for_create(
      user: {
        id: current_user.webauthn_id,
        name: current_user.email,
        display_name: current_user.email
      },
      exclude: current_user.webauthn_credentials.pluck(:external_id),
      rp: {
        name: "BrightTalk"
      }
    )

    # セッションにチャレンジを保存
    session[:webauthn_challenge] = @options.challenge
  end

  def create
    webauthn_credential = WebAuthn::Credential.from_create(credential_params)

    begin
      # Origin検証を含む検証を実行
      webauthn_credential.verify(
        session[:webauthn_challenge],
        origin: request_origin,
        rp_id: webauthn_rp_id
      )

      # データベースに保存
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

    rescue WebAuthn::OriginVerificationError => e
      Rails.logger.error "WebAuthn Origin Error: #{e.message}"
      Rails.logger.error "Expected origin: #{request_origin}"
      Rails.logger.error "RP ID: #{webauthn_rp_id}"

      render json: {
        success: false,
        error: "WebAuthn認証の設定に失敗しました: オリジンが一致しません"
      }, status: :unprocessable_entity

    rescue => e
      Rails.logger.error "WebAuthn Error: #{e.message}"

      render json: {
        success: false,
        error: "WebAuthn認証の設定に失敗しました: #{e.class.name}"
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