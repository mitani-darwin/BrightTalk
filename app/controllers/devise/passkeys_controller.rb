class Devise::PasskeysController < DeviseController
  prepend_before_action :authenticate_user!, only: [ :new, :create, :destroy ]
  before_action :set_passkey, only: [ :destroy ]

  def index
    @passkeys = current_user.passkeys.order(created_at: :desc)
  end

  def new
    Rails.logger.info "Devise::Passkeys new action - Current user: #{current_user&.id}"

    @label = params[:label] || "メインデバイス"
    @first_time = params[:first_time] == "true"

    # Passkey登録用のチャレンジを生成
    challenge = SecureRandom.urlsafe_base64(32)
    session[:passkey_creation_challenge] = challenge

    # WebAuthn Credential Creation Options
    @passkey_options = {
      challenge: challenge,
      rp: {
        id: WebAuthn.configuration.rp_id,
        name: WebAuthn.configuration.rp_name
      },
      user: {
        id: Base64.urlsafe_encode64("user_#{current_user.id}", padding: false),
        name: current_user.email,
        displayName: current_user.name || current_user.email
      },
      pubKeyCredParams: [ { type: "public-key", alg: -7 } ], # ES256
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
      format.json { render json: { passkey_options: @passkey_options } }
    end
  end

  def create
    Rails.logger.info "Devise::PasskeysController#create called"

    begin
      stored_challenge = session[:passkey_creation_challenge]

      if stored_challenge.blank?
        error_message = "登録チャレンジが見つかりません。再度お試しください。"
        Rails.logger.error "Creation challenge not found in session"

        respond_to do |format|
          format.html { redirect_to new_passkey_path, alert: error_message }
          format.json { render json: { error: error_message }, status: :unprocessable_content }
        end
        return
      end

      credential_data = params[:credential]
      if credential_data.blank?
        error_message = "認証データが提供されていません"
        Rails.logger.error "Credential data is blank"

        respond_to do |format|
          format.html { redirect_to new_passkey_path, alert: error_message }
          format.json { render json: { error: error_message }, status: :unprocessable_content }
        end
        return
      end

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

      webauthn_credential.verify(stored_challenge.to_s)

      # データベースに保存
      label = params[:label].presence || "パスキー"
      new_passkey = current_user.passkeys.build(
        identifier: webauthn_credential.id,
        public_key: webauthn_credential.public_key,
        label: label,
        sign_count: webauthn_credential.sign_count
      )

      if new_passkey.save
        session.delete(:passkey_creation_challenge)

        respond_to do |format|
          format.html { redirect_to user_passkeys_path, notice: "パスキー認証が正常に登録されました" }
          format.json {
            render json: {
              success: true,
              redirect_url: user_passkeys_path,
              message: "パスキー認証が正常に登録されました"
            }
          }
        end
      else
        error_message = "パスキー認証の保存に失敗しました: #{new_passkey.errors.full_messages.join(', ')}"

        respond_to do |format|
          format.html { redirect_to new_passkey_path, alert: error_message }
          format.json { render json: { error: error_message }, status: :unprocessable_content }
        end
      end

    rescue WebAuthn::Error => e
      Rails.logger.error "Passkey registration failed: #{e.message}"
      error_message = "パスキー認証の登録に失敗しました: #{e.message}"

      respond_to do |format|
        format.html { redirect_to new_passkey_path, alert: error_message }
        format.json { render json: { error: error_message }, status: :unprocessable_content }
      end
    end
  end

  def destroy
    if @passkey.destroy
      Rails.logger.info "Passkey deleted: #{@passkey.id}"
      redirect_to user_passkeys_path, notice: "パスキー認証が削除されました"
    else
      Rails.logger.error "Failed to delete Passkey: #{@passkey.errors.full_messages}"
      redirect_to user_passkeys_path, alert: "パスキー認証の削除に失敗しました"
    end
  end

  private

  def authenticate_scope!
    send(:"authenticate_#{resource_name}!", force: true)
    self.resource = send(:"current_#{resource_name}")
  end

  def set_passkey
    @passkey = current_user.passkeys.find(params[:id])
  rescue ActiveRecord::RecordNotFound
    Rails.logger.error "Passkey not found: #{params[:id]}"
    redirect_to user_passkeys_path, alert: "パスキー認証が見つかりませんでした"
  end
end
