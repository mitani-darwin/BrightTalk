
class WebauthnCredentialsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_webauthn_credential, only: [:show, :destroy]

  def index
    @webauthn_credentials = current_user.webauthn_credentials.order(:created_at)
  end

  def new
    @nickname = params[:nickname] || "メインデバイス"

    # セッションにuser_idを保存（webauthn_idの代わりに使用）
    user_id = current_user.id.to_s.ljust(64, '0') # 64文字にパディング
    user_id = user_id[0..63] if user_id.length > 64 # 最大64文字

    # WebAuthn用の設定
    @webauthn_options = WebAuthn::Credential.options_for_create(
      user: {
        id: Base64.urlsafe_encode64(user_id, padding: false),
        name: current_user.email,
        display_name: current_user.name
      },
      rp: {
        id: Rails.env.development? ? "localhost" : "yourdomain.com",
        name: "BrightTalk"
      },
      exclude: current_user.webauthn_credentials.pluck(:external_id)
    )

    session[:creation_challenge] = @webauthn_options.challenge
    Rails.logger.info "WebAuthn options: #{@webauthn_options.inspect}"
  end

  def create
    Rails.logger.info "WebAuthn create params: #{params.inspect}"

    begin
      webauthn_credential = WebAuthn::Credential.from_create(credential_params)

      # チャレンジの検証
      webauthn_credential.verify(session[:creation_challenge])

      # 認証情報をデータベースに保存
      current_user.webauthn_credentials.create!(
        nickname: params[:nickname] || "メインデバイス",
        external_id: webauthn_credential.id,
        public_key: webauthn_credential.public_key,
        sign_count: webauthn_credential.sign_count
      )

      session.delete(:creation_challenge)

      redirect_to webauthn_credentials_path, notice: 'WebAuthn認証が正常に設定されました。'
    rescue WebAuthn::Error => e
      Rails.logger.error "WebAuthn registration failed: #{e.message}"
      Rails.logger.error "WebAuthn registration backtrace: #{e.backtrace}"
      redirect_to new_webauthn_credential_path, alert: "WebAuthn認証の設定に失敗しました: #{e.message}"
    rescue StandardError => e
      Rails.logger.error "Unexpected error during WebAuthn registration: #{e.message}"
      Rails.logger.error "Backtrace: #{e.backtrace}"
      redirect_to new_webauthn_credential_path, alert: 'WebAuthn認証の設定中に予期しないエラーが発生しました。'
    end
  end

  def destroy
    @webauthn_credential.destroy
    redirect_to webauthn_credentials_path, notice: 'WebAuthn認証を削除しました。'
  end

  private

  def set_webauthn_credential
    @webauthn_credential = current_user.webauthn_credentials.find(params[:id])
  end

  def credential_params
    params.require(:credential).permit(:id, :rawId, :type, :response => [:clientDataJSON, :attestationObject])
  end
end