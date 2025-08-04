class WebauthnCredentialsController < ApplicationController
  before_action :authenticate_user!

  def new
    # WebAuthnオプションを生成
    @webauthn_options = WebAuthn::Credential.options_for_create(
      user: {
        id: current_user.webauthn_id,
        name: current_user.email,
        display_name: current_user.email
      },
      exclude: current_user.webauthn_credentials.pluck(:external_id),
      rp: {
        name: "BrightTalk",
        id: webauthn_rp_id
      },
      # 本番環境では追加の設定
      authenticator_selection: {
        authenticator_attachment: 'platform',
        resident_key: 'preferred',
        user_verification: 'required'
      },
      timeout: 60_000
    )

    # セッションにチャレンジを保存
    session[:webauthn_challenge] = @webauthn_options.challenge

    # 本番環境でのデバッグログ
    Rails.logger.info "WebAuthn options generated for #{current_user.email}"
    Rails.logger.info "Challenge: #{@webauthn_options.challenge}"
    Rails.logger.info "RP ID: #{webauthn_rp_id}"
    Rails.logger.info "Origin: #{request_origin}"
  end

  def create
    Rails.logger.info "WebAuthn create called with params: #{params.keys}"

    begin
      webauthn_credential = WebAuthn::Credential.from_create(credential_params)

      Rails.logger.info "WebAuthn credential parsed successfully"
      Rails.logger.info "Challenge from session: #{session[:webauthn_challenge]}"
      Rails.logger.info "Origin: #{request_origin}"
      Rails.logger.info "RP ID: #{webauthn_rp_id}"

      webauthn_credential.verify(
        session[:webauthn_challenge],
        origin: request_origin,
        rp_id: webauthn_rp_id
      )

      Rails.logger.info "WebAuthn verification successful"

      current_user.webauthn_credentials.create!(
        external_id: webauthn_credential.id,
        public_key: webauthn_credential.public_key,
        sign_count: webauthn_credential.sign_count,
        name: params[:name] || 'メインデバイス'
      )

      Rails.logger.info "WebAuthn credential saved to database"

      session.delete(:webauthn_challenge)

      render json: {
        success: true,
        message: "WebAuthn認証が正常に登録されました",
        redirect_url: webauthn_credentials_path
      }

    rescue WebAuthn::Error => e
      Rails.logger.error "WebAuthn Error: #{e.message}"
      Rails.logger.error "WebAuthn Error Class: #{e.class}"
      Rails.logger.error "Backtrace: #{e.backtrace.first(10).join("\n")}"

      render json: {
        success: false,
        error: "WebAuthn認証の登録に失敗しました: #{e.message}"
      }, status: :unprocessable_entity

    rescue => e
      Rails.logger.error "General Error: #{e.message}"
      Rails.logger.error "Error Class: #{e.class}"
      Rails.logger.error "Backtrace: #{e.backtrace.first(10).join("\n")}"

      render json: {
        success: false,
        error: "予期しないエラーが発生しました"
      }, status: :internal_server_error
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