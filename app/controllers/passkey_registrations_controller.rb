class PasskeyRegistrationsController < ApplicationController
  before_action :ensure_user_not_signed_in
  before_action :find_pending_user, only: [ :register_passkey, :verify_passkey ]

  def new
    @user = User.new

    # CSRFトークンが確実に生成されるよう明示的に設定
    request.session_options[:skip] = false

    # developmentまたはtest環境でのデバッグ情報
    if Rails.env.development? || Rails.env.test?
      Rails.logger.debug "CSRF token generated: #{form_authenticity_token.present?}"
    end
  end

  def create
    @user = User.new(user_params)

    # バリデーションチェック（データベースに保存せずに）
    if @user.valid?
      # 基本情報をセッションに保存
      session[:pending_user_data] = {
        name: @user.name,
        email: @user.email
      }

      respond_to do |format|
        format.json {
          render json: {
            success: true,
            message: "基本情報を確認しました。パスキーを設定してください。"
          }
        }
        format.html {
          # HTMLで来た場合はJSON本文を返さずリダイレクト（生JSONが表示されるのを防止）
          redirect_to new_passkey_registration_path, notice: "基本情報を確認しました。パスキーを設定してください。"
        }
        format.any {
          head :ok
        }
      end
    else
      respond_to do |format|
        format.html { render :new, status: :unprocessable_content }
        format.json {
          render json: {
            success: false,
            errors: @user.errors.full_messages
          }, status: :unprocessable_content
        }
      end
    end
  end

  def register_passkey
    Rails.logger.info "Generating passkey registration challenge for pending user: #{@pending_user_data['email']}"

    challenge = SecureRandom.urlsafe_base64(32)
    session[:passkey_registration_challenge] = challenge

    rp_id = Rails.env.development? ? "localhost" : "www.brighttalk.jp"

    # 一意なユーザーIDを生成（メールアドレスをベースに）
    temp_user_id = Digest::SHA256.hexdigest(@pending_user_data["email"])

    # WebAuthn登録オプション生成
    registration_options = {
      challenge: challenge,
      rp: {
        id: rp_id,
        name: "BrightTalk"
      },
      user: {
        id: Base64.urlsafe_encode64(temp_user_id),
        name: @pending_user_data["email"],
        displayName: @pending_user_data["name"]
      },
      pubKeyCredParams: [
        { type: "public-key", alg: -7 },  # ES256
        { type: "public-key", alg: -257 } # RS256
      ],
      timeout: 300000,
      attestation: "direct",
      authenticatorSelection: {
        authenticatorAttachment: "platform",
        residentKey: "required",
        userVerification: "required"
      },
      excludeCredentials: [] # 新規ユーザーなので既存クレデンシャルはなし
    }

    render json: {
      success: true,
      publicKey: registration_options
    }
  end

  def verify_passkey
    Rails.logger.info "Verifying passkey registration for pending user: #{@pending_user_data['email']}"

    begin
      challenge = session[:passkey_registration_challenge]

      if challenge.blank?
        render json: { error: "登録セッションが無効です。最初からやり直してください。" }, status: :bad_request
        return
      end

      # 修正後
      credential_params = params.require(:credential)

      # パラメータの検証とログ出力
      Rails.logger.debug "Credential params: #{credential_params.inspect}"

      # 必須パラメータのnilチェック
      if credential_params[:id].blank?
        render json: { error: "認証ID が不足しています" }, status: :bad_request
        return
      end

      if credential_params[:rawId].blank?
        render json: { error: "認証rawID が不足しています" }, status: :bad_request
        return
      end

      response_params = credential_params[:response]
      if response_params.blank?
        render json: { error: "認証レスポンスが不足しています" }, status: :bad_request
        return
      end

      # より詳細なパラメータ検証とログ
      Rails.logger.debug "clientDataJSON: #{response_params[:clientDataJSON]&.class} - #{response_params[:clientDataJSON]&.length} chars"
      Rails.logger.debug "attestationObject: #{response_params[:attestationObject]&.class} - #{response_params[:attestationObject]&.length} chars"

      if response_params[:clientDataJSON].blank?
        Rails.logger.error "clientDataJSON is blank or nil"
        render json: { error: "clientDataJSON が不足しています" }, status: :bad_request
        return
      end

      if response_params[:attestationObject].blank?
        render json: { error: "attestationObject が不足しています" }, status: :bad_request
        return
      end

      Rails.logger.debug "All required parameters present, creating WebAuthn credential"

      # WebAuthn認証情報を構築（文字列形式で明示的に指定＆詳細エラーハンドリング）
      begin
          credential_data = {
            "type" => credential_params[:type].to_s.presence || "public-key",
            "id" => credential_params[:id].to_s,
            "rawId" => credential_params[:rawId].to_s,
            "response" => {
              "clientDataJSON" => response_params[:clientDataJSON].to_s,
              "attestationObject" => response_params[:attestationObject].to_s
            }
          }

          Rails.logger.debug "Credential data for WebAuthn: #{credential_data.inspect}"

          webauthn_credential = WebAuthn::Credential.from_create(credential_data)
          Rails.logger.debug "WebAuthn credential created successfully"

      rescue => creation_error
        Rails.logger.error "WebAuthn credential creation failed: #{creation_error.class}: #{creation_error.message}"
        Rails.logger.error "Creation error backtrace: #{creation_error.backtrace.first(5).join(', ')}"
        render json: { error: "認証データの処理に失敗しました: #{creation_error.message}" }, status: :bad_request
        return
      end

      # パスキー登録を検証（詳細なエラーハンドリング付き）
      begin
        Rails.logger.debug "Starting WebAuthn verification with challenge: #{challenge.present? ? 'present' : 'nil'}"
        webauthn_credential.verify(challenge)
        Rails.logger.debug "WebAuthn verification successful"
      rescue WebAuthn::OriginVerificationError => e
        Rails.logger.error "Origin verification failed: #{e.message}"
        render json: { error: "認証元の検証に失敗しました" }, status: :unauthorized
        return
      rescue WebAuthn::ChallengeVerificationError => e
        Rails.logger.error "Challenge verification failed: #{e.message}"
        render json: { error: "認証チャレンジの検証に失敗しました" }, status: :unauthorized
        return
      rescue => verification_error
        Rails.logger.error "WebAuthn verification error: #{verification_error.class}: #{verification_error.message}"
        Rails.logger.error "Verification error backtrace: #{verification_error.backtrace.first(10).join(', ')}"
        render json: { error: "パスキー検証に失敗しました: #{verification_error.message}" }, status: :unauthorized
        return
      end

      # パスキー検証成功後にユーザーを作成（仮登録状態）
      User.transaction do
        # 一時パスワードを生成して設定（後で削除）
        chars = [ *("A".."Z"), *("a".."z"), *("0".."9"), *%w[! @ # $ % ^ & *] ]
        temp_password = Array.new(16) { chars.sample }.join

        @user = User.create!(
          name: @pending_user_data["name"],
          email: @pending_user_data["email"],
          password: temp_password
        )

        # パスキーを保存（仮登録状態でも保存）
        passkey = @user.webauthn_credentials.create!(
          external_id: credential_params[:id],
          public_key: webauthn_credential.public_key,
          nickname: params[:nickname] || "メインパスキー",
          sign_count: webauthn_credential.sign_count
        )

        # 一時パスワードを削除してパスキー認証のみにする
        @user.update_column(:encrypted_password, "")
        Rails.logger.info "Password removed without notification email for passkey-only user: #{@user.email}"
      end

      # 確認メールを送信（仮登録状態なので確認が必要）
      begin
        @user.send_confirmation_instructions
        Rails.logger.info "Confirmation instructions sent to: #{@user.email}"
      rescue => mail_error
        Rails.logger.error "Failed to send confirmation instructions: #{mail_error.message}"
        # メール送信失敗は登録処理を止めない
      end

      # セッションをクリア
      session.delete(:passkey_registration_challenge)
      session.delete(:pending_user_data)

      Rails.logger.info "User created and passkey registration successful for user: #{@user.id}"

      render json: {
        success: true,
        message: "パスキーの登録が完了しました。メールアドレスに送信された確認メールのリンクをクリックして、登録を完了してください。",
        show_confirmation_notice: true
      }

    rescue WebAuthn::Error => e
      Rails.logger.error "Passkey verification failed: #{e.message}"
      render json: {
        error: "パスキーの登録に失敗しました: #{e.message}"
      }, status: :unauthorized
    rescue => e
      Rails.logger.error "Passkey registration error: #{e.message}"
      render json: {
        error: "登録処理中にエラーが発生しました: #{e.message}"
      }, status: :internal_server_error
    end
  end

  private

  def user_params
    params.require(:user).permit(:name, :email)
  end

  def ensure_user_not_signed_in
    redirect_to root_path if user_signed_in?
  end

  def find_pending_user
    pending_user_data = session[:pending_user_data]

    if pending_user_data.nil?
      render json: { error: "登録セッションが見つかりません。最初からやり直してください。" }, status: :not_found
      return
    end

    # セッションからユーザー情報を復元（まだ保存されていない）
    @pending_user_data = pending_user_data
  end

  def after_sign_up_path_for(resource)
    root_path
  end
end
