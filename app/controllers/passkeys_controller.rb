class PasskeysController < ApplicationController
  before_action :authenticate_user!
  before_action :set_passkey, only: [:show, :destroy]

  def index
    @passkeys = current_user.passkeys.order(created_at: :desc)
    @passkeys_enabled = current_user.passkeys.exists?
  end

  def show
  end

  def new
    Rails.logger.info "Passkey new action - Current user: #{current_user&.id}"

    @label = params[:label] || "メインデバイス"
    @first_time = params[:first_time] == 'true'

    # Passkey登録用のチャレンジを生成
    challenge = SecureRandom.urlsafe_base64(32)
    session[:passkey_creation_challenge] = challenge

    # WebAuthn Credential Creation Options
    @webauthn_options = {
      challenge: challenge,
      rp: {
        id: Rails.env.development? ? "localhost" : "www.brighttalk.jp",
        name: "BrightTalk"
      },
      user: {
        id: Base64.urlsafe_encode64("user_#{current_user.id}"),
        name: current_user.email,
        displayName: current_user.name || current_user.email
      },
      pubKeyCredParams: [{ type: "public-key", alg: -7 }], # ES256
      timeout: 300000,
      attestation: "direct",
      authenticatorSelection: {
        authenticatorAttachment: "platform",
        userVerification: "required"
      },
      excludeCredentials: current_user.passkeys.pluck(:identifier).map { |id|
        { type: "public-key", id: id }
      }
    }

    Rails.logger.info "Passkey registration options generated for user: #{current_user.id}"

    respond_to do |format|
      format.html
      format.json { render json: { webauthn_options: @webauthn_options } }
    end
  end

  def create
    Rails.logger.info "PasskeysController#create called"
    Rails.logger.info "Params: #{params.inspect}"

    begin
      # セッションからチャレンジを取得
      stored_challenge = session[:passkey_creation_challenge]

      if stored_challenge.blank?
        error_message = "登録チャレンジが見つかりません。再度お試しください。"
        Rails.logger.error "Creation challenge not found in session"

        respond_to do |format|
          format.html { redirect_to new_passkey_path, alert: error_message }
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
          format.html { redirect_to new_passkey_path, alert: error_message }
          format.json { render json: { error: error_message }, status: :unprocessable_entity }
        end
        return
      end

      Rails.logger.info "Processing Passkey registration for user: #{current_user.id}"
      Rails.logger.info "Credential ID: #{credential_data[:id]}"

      # WebAuthn認証情報を検証
      webauthn_credential = WebAuthn::Credential.from_create({
                                                               "type" => credential_data[:type],
                                                               "id" => credential_data[:id],
                                                               "rawId" => credential_data[:rawId],
                                                               "response" => {
                                                                 "clientDataJSON" => credential_data[:response][:clientDataJSON],
                                                                 "attestationObject" => credential_data[:response][:attestationObject]
                                                               }
                                                             })

      # 認証を検証
      webauthn_credential.verify(stored_challenge.to_s)

      Rails.logger.info "Passkey credential verification successful"

      # データベースに認証情報を保存
      label = params[:label].presence || "パスキー"
      new_passkey = current_user.passkeys.build(
        identifier: webauthn_credential.id,
        public_key: webauthn_credential.public_key,
        label: label,
        sign_count: webauthn_credential.sign_count
      )

      if new_passkey.save
        Rails.logger.info "Passkey saved successfully: #{new_passkey.id}"

        # セッションからチャレンジを削除
        session.delete(:passkey_creation_challenge)

        respond_to do |format|
          format.html { redirect_to passkeys_path, notice: "パスキー認証が正常に登録されました" }
          format.json {
            render json: {
              success: true,
              redirect_url: passkeys_path,
              message: "パスキー認証が正常に登録されました"
            }
          }
        end
      else
        Rails.logger.error "Failed to save Passkey: #{new_passkey.errors.full_messages}"
        error_message = "パスキー認証の保存に失敗しました: #{new_passkey.errors.full_messages.join(', ')}"

        respond_to do |format|
          format.html { redirect_to new_passkey_path, alert: error_message }
          format.json { render json: { error: error_message }, status: :unprocessable_entity }
        end
      end

    rescue WebAuthn::Error => e
      Rails.logger.error "Passkey registration failed: #{e.message}"
      error_message = "パスキー認証の登録に失敗しました: #{e.message}"

      respond_to do |format|
        format.html { redirect_to new_passkey_path, alert: error_message }
        format.json { render json: { error: error_message }, status: :unprocessable_entity }
      end
    rescue StandardError => e
      Rails.logger.error "Unexpected error during Passkey registration: #{e.message}"
      error_message = "パスキー認証の登録中に予期しないエラーが発生しました。"

      respond_to do |format|
        format.html { redirect_to new_passkey_path, alert: error_message }
        format.json { render json: { error: error_message }, status: :internal_server_error }
      end
    end
  end

  def destroy
    if @passkey.destroy
      Rails.logger.info "Passkey deleted: #{@passkey.id}"

      redirect_to passkeys_path, notice: "パスキー認証が削除されました"
    else
      Rails.logger.error "Failed to delete Passkey: #{@passkey.errors.full_messages}"
      redirect_to passkeys_path, alert: "パスキー認証の削除に失敗しました"
    end
  end

  private

  def set_passkey
    @passkey = current_user.passkeys.find(params[:id])
  rescue ActiveRecord::RecordNotFound
    Rails.logger.error "Passkey not found: #{params[:id]}"
    redirect_to passkeys_path, alert: "パスキー認証が見つかりませんでした"
  end

  def passkey_params
    params.require(:passkey).permit(:label)
  end
end