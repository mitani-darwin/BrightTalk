class WebauthnCredentialsController < ApplicationController
  before_action :authenticate_user!

  def index
    Rails.logger.info "WebauthnCredentialsController#index called for user: #{current_user.id}"
    @webauthn_credentials = current_user.webauthn_credentials.order(:created_at)
    Rails.logger.info "Found #{@webauthn_credentials.count} credentials"
  end

  def new
    Rails.logger.info "WebauthnCredentialsController#new called for user: #{current_user.id}"
    Rails.logger.info "User email: #{current_user.email}"
    Rails.logger.info "WebAuthn ID: #{current_user.webauthn_id}"
    Rails.logger.info "Existing credentials: #{current_user.webauthn_credentials.count}"

    begin
      # WebAuthn設定を作成（グローバル設定を使用）
      WebAuthn.configuration.origin = request_origin
      WebAuthn.configuration.rp_id = webauthn_rp_id
      WebAuthn.configuration.rp_name = "BrightTalk"

      # WebAuthnオプションを生成
      @webauthn_options = WebAuthn::Credential.options_for_create(
        user: {
          id: current_user.webauthn_id,
          name: current_user.email,
          display_name: current_user.name || current_user.email
        },
        exclude: current_user.webauthn_credentials.pluck(:external_id),
        authenticator_selection: {
          authenticator_attachment: 'platform',
          resident_key: 'preferred',
          user_verification: 'required'
        },
        timeout: 60_000
      )

      Rails.logger.info "WebAuthn options generated successfully"
      Rails.logger.info "Options class: #{@webauthn_options.class}"
      Rails.logger.info "Challenge present: #{@webauthn_options&.challenge&.present?}"

      # セッションにチャレンジを保存
      if @webauthn_options&.challenge
        session[:webauthn_challenge] = @webauthn_options.challenge
        Rails.logger.info "Challenge saved to session"
      else
        Rails.logger.error "Challenge is nil!"
      end

      # 本番環境でのデバッグログ
      Rails.logger.info "RP ID: #{webauthn_rp_id}"
      Rails.logger.info "Origin: #{request_origin}"

    rescue => e
      Rails.logger.error "Error generating WebAuthn options: #{e.message}"
      Rails.logger.error "Error class: #{e.class}"
      Rails.logger.error "Backtrace: #{e.backtrace.first(10).join("\n")}"

      # エラー時のフォールバック
      flash[:alert] = "WebAuthn設定の初期化に失敗しました。再度お試しください。"
      redirect_to webauthn_credentials_path
    end
  end

  def create
    Rails.logger.info "=== WebAuthn create action started ==="
    Rails.logger.info "Params keys: #{params.keys}"
    Rails.logger.info "Current user: #{current_user&.id}"
    Rails.logger.info "Session challenge: #{session[:webauthn_challenge].present? ? 'present' : 'missing'}"

    begin
      # WebAuthn設定を作成（グローバル設定を使用）
      WebAuthn.configuration.origin = request_origin
      WebAuthn.configuration.rp_id = webauthn_rp_id
      WebAuthn.configuration.rp_name = "BrightTalk"

      # パラメータの確認
      if params[:credential].blank?
        Rails.logger.error "Credential params are missing!"
        render json: {
          success: false,
          error: "認証データが送信されていません"
        }, status: :bad_request
        return
      end

      # セッションチャレンジの確認
      unless session[:webauthn_challenge].present?
        Rails.logger.error "Session challenge is missing!"
        render json: {
          success: false,
          error: "認証セッションが無効です。ページを再読み込みしてください。"
        }, status: :bad_request
        return
      end

      # WebAuthn::Credential.from_createを実行
      Rails.logger.info "Creating WebAuthn credential from params..."
      webauthn_credential = WebAuthn::Credential.from_create(credential_params)
      Rails.logger.info "WebAuthn credential created successfully"

      # 検証処理（最新WebAuthnライブラリ対応）
      Rails.logger.info "Starting verification..."
      verification_result = webauthn_credential.verify(
        session[:webauthn_challenge]
      )

      Rails.logger.info "WebAuthn verification successful"
      Rails.logger.info "Verification result: #{verification_result}"

      # データベース保存
      Rails.logger.info "Saving to database..."
      new_credential = current_user.webauthn_credentials.create!(
        external_id: webauthn_credential.id,
        public_key: webauthn_credential.public_key,
        sign_count: webauthn_credential.sign_count,
        nickname: params[:name] || 'メインデバイス'
      )

      Rails.logger.info "WebAuthn credential saved to database with ID: #{new_credential.id}"

      session.delete(:webauthn_challenge)

      render json: {
        success: true,
        message: "WebAuthn認証が正常に登録されました",
        redirect_url: webauthn_credentials_path
      }

    rescue ActionController::ParameterMissing => e
      Rails.logger.error "Parameter missing: #{e.message}"
      render json: {
        success: false,
        error: "必要なパラメータが不足しています: #{e.param}"
      }, status: :bad_request

    rescue WebAuthn::Error => e
      Rails.logger.error "WebAuthn Error: #{e.message}"
      Rails.logger.error "WebAuthn Error Class: #{e.class}"

      render json: {
        success: false,
        error: "WebAuthn認証の設定に失敗しました: #{e.message}"
      }, status: :unprocessable_entity

    rescue ActiveRecord::RecordInvalid => e
      Rails.logger.error "Database validation error: #{e.message}"
      Rails.logger.error "Record errors: #{e.record.errors.full_messages}"

      render json: {
        success: false,
        error: "データベース保存エラー: #{e.record.errors.full_messages.join(', ')}"
      }, status: :unprocessable_entity

    rescue => e
      Rails.logger.error "=== UNEXPECTED ERROR ==="
      Rails.logger.error "Error: #{e.message}"
      Rails.logger.error "Error Class: #{e.class}"
      Rails.logger.error "Backtrace:"
      e.backtrace.each { |line| Rails.logger.error "  #{line}" }
      Rails.logger.error "=== END ERROR ==="

      render json: {
        success: false,
        error: "予期しないエラーが発生しました: #{e.message}"
      }, status: :internal_server_error
    end
  end

  def destroy
    @credential = current_user.webauthn_credentials.find(params[:id])
    @credential.destroy
    redirect_to webauthn_credentials_path, notice: "WebAuthn認証を削除しました。"
  rescue ActiveRecord::RecordNotFound
    redirect_to webauthn_credentials_path, alert: "認証情報が見つかりません。"
  end

  private

  def credential_params
    Rails.logger.info "Processing credential params..."
    permitted_params = params.require(:credential).permit(:id, :rawId, :type, response: [:clientDataJSON, :attestationObject])
    Rails.logger.info "Permitted params: #{permitted_params.inspect}"
    permitted_params
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