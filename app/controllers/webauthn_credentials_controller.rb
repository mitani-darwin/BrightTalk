class WebauthnCredentialsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_webauthn_credential, only: [:show, :destroy]

  def index
    @webauthn_credentials = current_user.webauthn_credentials.order(created_at: :desc)
    @webauthn_enabled = current_user.webauthn_enabled?
  end

  def show
  end

  def new
    @nickname = params[:nickname] || "メインデバイス"

    # WebAuthn登録用のオプションを生成
    @webauthn_options = WebAuthn::Credential.options_for_create(
      user: {
        id: current_user.webauthn_id,
        name: current_user.email,
        display_name: current_user.name || current_user.email
      },
      exclude: current_user.webauthn_credentials.pluck(:external_id)
    )

    # チャレンジをセッションに保存
    session[:creation_challenge] = @webauthn_options.challenge

    Rails.logger.info "WebAuthn registration options generated for user: #{current_user.id}"
    Rails.logger.info "Challenge stored: #{session[:creation_challenge]}"

    respond_to do |format|
      format.html
      format.json { render json: { webauthn_options: @webauthn_options } }
    end
  end

  def create
    Rails.logger.info "WebauthnCredentialsController#create called"
    Rails.logger.info "Params: #{params.inspect}"
    Rails.logger.info "Session keys: #{session.keys}"

    begin
      # セッションからチャレンジを取得
      stored_challenge = session[:creation_challenge]

      Rails.logger.info "Stored challenge: #{stored_challenge&.present? ? 'present' : 'missing'}"

      if stored_challenge.blank?
        error_message = "登録チャレンジが見つかりません。再度お試しください。"
        Rails.logger.error "Creation challenge not found in session"

        respond_to do |format|
          format.html { redirect_to new_webauthn_credential_path, alert: error_message }
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
          format.html { redirect_to new_webauthn_credential_path, alert: error_message }
          format.json { render json: { error: error_message }, status: :unprocessable_entity }
        end
        return
      end

      Rails.logger.info "Processing WebAuthn registration for user: #{current_user.id}"
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

      Rails.logger.info "WebAuthn credential verification successful"

      # データベースに認証情報を保存
      name = params[:name].presence || "パスキー"
      new_credential = current_user.webauthn_credentials.build(
        external_id: webauthn_credential.id,
        public_key: webauthn_credential.public_key,
        nickname: name,
        sign_count: webauthn_credential.sign_count
      )

      if new_credential.save
        Rails.logger.info "WebAuthn credential saved successfully: #{new_credential.id}"

        # セッションからチャレンジを削除
        session.delete(:creation_challenge)

        # ユーザーのWebAuthn設定を有効にする
        unless current_user.webauthn_enabled?
          current_user.update!(webauthn_enabled: true)
          Rails.logger.info "WebAuthn enabled for user: #{current_user.id}"
        end

        respond_to do |format|
          format.html { redirect_to webauthn_credentials_path, notice: "パスキー認証が正常に登録されました" }
          format.json {
            render json: {
              success: true,
              redirect_url: webauthn_credentials_path,
              message: "パスキー認証が正常に登録されました"
            }
          }
        end
      else
        Rails.logger.error "Failed to save WebAuthn credential: #{new_credential.errors.full_messages}"
        error_message = "パスキー認証の保存に失敗しました: #{new_credential.errors.full_messages.join(', ')}"

        respond_to do |format|
          format.html { redirect_to new_webauthn_credential_path, alert: error_message }
          format.json { render json: { error: error_message }, status: :unprocessable_entity }
        end
      end

    rescue WebAuthn::Error => e
      Rails.logger.error "WebAuthn registration failed: #{e.message}"
      Rails.logger.error "WebAuthn registration backtrace: #{e.backtrace.join("\n")}"

      error_message = "パスキー認証の登録に失敗しました: #{e.message}"

      respond_to do |format|
        format.html { redirect_to new_webauthn_credential_path, alert: error_message }
        format.json { render json: { error: error_message }, status: :unprocessable_entity }
      end
    rescue StandardError => e
      Rails.logger.error "Unexpected error during WebAuthn registration: #{e.message}"
      Rails.logger.error "Backtrace: #{e.backtrace.join("\n")}"

      error_message = "パスキー認証の登録中に予期しないエラーが発生しました。"

      respond_to do |format|
        format.html { redirect_to new_webauthn_credential_path, alert: error_message }
        format.json { render json: { error: error_message }, status: :internal_server_error }
      end
    end
  end

  def destroy
    if @webauthn_credential.destroy
      Rails.logger.info "WebAuthn credential deleted: #{@webauthn_credential.id}"

      # 最後の認証情報が削除された場合は、WebAuthn設定を無効にする
      unless current_user.webauthn_credentials.exists?
        current_user.update!(webauthn_enabled: false)
        Rails.logger.info "WebAuthn disabled for user: #{current_user.id}"
      end

      redirect_to webauthn_credentials_path, notice: "パスキー認証が削除されました"
    else
      Rails.logger.error "Failed to delete WebAuthn credential: #{@webauthn_credential.errors.full_messages}"
      redirect_to webauthn_credentials_path, alert: "パスキー認証の削除に失敗しました"
    end
  end

  private

  def set_webauthn_credential
    @webauthn_credential = current_user.webauthn_credentials.find(params[:id])
  rescue ActiveRecord::RecordNotFound
    Rails.logger.error "WebAuthn credential not found: #{params[:id]}"
    redirect_to webauthn_credentials_path, alert: "パスキー認証が見つかりませんでした"
  end

  def webauthn_credential_params
    params.require(:webauthn_credential).permit(:nickname)
  end
end
