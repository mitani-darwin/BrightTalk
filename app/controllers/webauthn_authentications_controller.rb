
class WebauthnCredentialsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_webauthn_credential, only: [:show, :destroy]

  def index
    @webauthn_credentials = current_user.webauthn_credentials.order(:created_at)
  end

  def show
    # 詳細表示用のアクション
    Rails.logger.info "WebauthnCredentialsController#show called for credential: #{@webauthn_credential.id}"
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

    # チャレンジをセッションに保存（Base64エンコード済みの文字列として）
    session[:creation_challenge] = @webauthn_options.challenge
    Rails.logger.info "WebAuthn options: #{@webauthn_options.inspect}"
    Rails.logger.info "Stored challenge in session: #{session[:creation_challenge]}"
  end

  def create
    Rails.logger.info "=" * 50
    Rails.logger.info "WebAuthn create action started"
    Rails.logger.info "Request method: #{request.method}"
    Rails.logger.info "Request format: #{request.format}"
    Rails.logger.info "Request headers Accept: #{request.headers['Accept']}"
    Rails.logger.info "Request headers Content-Type: #{request.headers['Content-Type']}"
    Rails.logger.info "Params: #{params.inspect}"
    Rails.logger.info "Session challenge: #{session[:creation_challenge]}"
    Rails.logger.info "Current user webauthn_enabled before: #{current_user.webauthn_enabled}"
    Rails.logger.info "=" * 50

    begin
      # セッションからチャレンジを取得
      stored_challenge = session[:creation_challenge]
      if stored_challenge.blank?
        error_message = "セッションからチャレンジが見つかりません。再度お試しください。"
        Rails.logger.error "Challenge not found in session"

        respond_to do |format|
          format.html { redirect_to new_webauthn_credential_path, alert: error_message }
          format.json { render json: { success: false, error: error_message }, status: :unprocessable_entity }
        end
        return
      end

      # パラメータの取得と検証
      credential_data = params[:credential]
      if credential_data.blank?
        error_message = "認証情報が提供されていません"
        Rails.logger.error "Credential data is blank"

        respond_to do |format|
          format.html { redirect_to new_webauthn_credential_path, alert: error_message }
          format.json { render json: { success: false, error: error_message }, status: :unprocessable_entity }
        end
        return
      end

      Rails.logger.info "Creating WebAuthn credential with data: #{credential_data.inspect}"

      # WebAuthn認証情報を作成
      webauthn_credential = WebAuthn::Credential.from_create({
                                                               "type" => credential_data[:type],
                                                               "id" => credential_data[:id],
                                                               "rawId" => credential_data[:rawId],
                                                               "response" => {
                                                                 "clientDataJSON" => credential_data[:response][:clientDataJSON],
                                                                 "attestationObject" => credential_data[:response][:attestationObject]
                                                               }
                                                             })

      Rails.logger.info "WebAuthn credential created successfully"

      # チャレンジの検証（文字列として渡す）
      Rails.logger.info "Verifying with challenge: #{stored_challenge} (class: #{stored_challenge.class})"
      webauthn_credential.verify(stored_challenge.to_s)

      Rails.logger.info "WebAuthn credential verification successful"

      # データベーストランザクション内で認証情報を保存し、ユーザーの設定を更新
      ActiveRecord::Base.transaction do
        # 認証情報をデータベースに保存
        @webauthn_credential = current_user.webauthn_credentials.create!(
          nickname: params[:name] || params[:nickname] || "メインデバイス",
          external_id: webauthn_credential.id,
          public_key: webauthn_credential.public_key,
          sign_count: webauthn_credential.sign_count
        )

        Rails.logger.info "WebAuthn credential saved to database: #{@webauthn_credential.inspect}"

        # ユーザーのwebauthn_enabledフラグをtrueに設定
        current_user.update!(webauthn_enabled: true)
        Rails.logger.info "User webauthn_enabled updated to: #{current_user.webauthn_enabled}"

        # セッションからチャレンジを削除
        session.delete(:creation_challenge)

        Rails.logger.info "WebAuthn registration completed successfully for user: #{current_user.id}"
      end

      success_message = 'WebAuthn認証が正常に設定されました。次回ログイン時から生体認証でログインできます。'

      respond_to do |format|
        format.html {
          Rails.logger.info "Redirecting to HTML path"
          redirect_to webauthn_credentials_path, notice: success_message
        }
        format.json {
          Rails.logger.info "Returning JSON response"
          render json: {
            success: true,
            message: success_message,
            redirect_url: webauthn_credentials_path,
            webauthn_enabled: current_user.webauthn_enabled
          }, status: :ok
        }
      end

    rescue ActiveRecord::RecordInvalid => e
      Rails.logger.error "Database validation error: #{e.message}"
      Rails.logger.error "Database validation backtrace: #{e.backtrace.join("\n")}"

      error_message = "WebAuthn認証の保存に失敗しました: #{e.message}"

      respond_to do |format|
        format.html { redirect_to new_webauthn_credential_path, alert: error_message }
        format.json { render json: { success: false, error: error_message }, status: :unprocessable_entity }
      end
    rescue WebAuthn::Error => e
      Rails.logger.error "WebAuthn registration failed: #{e.message}"
      Rails.logger.error "WebAuthn registration backtrace: #{e.backtrace.join("\n")}"

      error_message = "WebAuthn認証の設定に失敗しました: #{e.message}"

      respond_to do |format|
        format.html { redirect_to new_webauthn_credential_path, alert: error_message }
        format.json { render json: { success: false, error: error_message }, status: :unprocessable_entity }
      end
    rescue StandardError => e
      Rails.logger.error "Unexpected error during WebAuthn registration: #{e.message}"
      Rails.logger.error "Backtrace: #{e.backtrace.join("\n")}"

      error_message = 'WebAuthn認証の設定中に予期しないエラーが発生しました。'

      respond_to do |format|
        format.html { redirect_to new_webauthn_credential_path, alert: error_message }
        format.json { render json: { success: false, error: error_message }, status: :internal_server_error }
      end
    end
  end

  def destroy
    Rails.logger.info "Destroying WebAuthn credential: #{@webauthn_credential.id} for user: #{current_user.id}"

    # WebAuthn認証を削除
    @webauthn_credential.destroy

    # 残りのWebAuthn認証がない場合は、webauthn_enabledをfalseに設定
    if current_user.webauthn_credentials.count == 0
      current_user.update!(webauthn_enabled: false)
      Rails.logger.info "User webauthn_enabled set to false (no credentials remaining)"
      notice_message = 'WebAuthn認証を削除しました。すべての認証が削除されたため、WebAuthn機能を無効にしました。'
    else
      notice_message = 'WebAuthn認証を削除しました。'
    end

    redirect_to webauthn_credentials_path, notice: notice_message
  end

  private

  def set_webauthn_credential
    @webauthn_credential = current_user.webauthn_credentials.find(params[:id])
  end

  def credential_params
    params.require(:credential).permit(:id, :rawId, :type, :response => [:clientDataJSON, :attestationObject])
  end
end