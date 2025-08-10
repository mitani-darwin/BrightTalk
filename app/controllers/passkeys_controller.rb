class PasskeysController < ApplicationController
  before_action :authenticate_user!
  before_action :set_passkey, only: [:show, :destroy]

  def index
    @passkeys = current_user.passkeys.order(:created_at)
  end

  def new
    @first_time = params[:first_time] == 'true'

    # デフォルトデバイス名をビューで使用するためにインスタンス変数として設定
    @default_device_name = default_device_name

    # WebAuthn registration options を生成
    @webauthn_options = generate_webauthn_options

    respond_to do |format|
      format.html
      format.json { render json: @webauthn_options }
    end
  end

  def create
    begin
      # WebAuthnの認証情報を検証
      webauthn_credential, stored_credential = verify_and_store_credential

      # Passkeyとして保存
      @passkey = current_user.passkeys.build(
        identifier: Passkey.normalize_identifier(stored_credential.external_id),
        public_key: stored_credential.public_key,
        sign_count: stored_credential.sign_count,
        label: passkey_params[:label] || default_device_name,
        last_used_at: Time.current
      )

      if @passkey.save
        # 新しいパスキー登録時の処理
        current_user.disable_password_after_passkey

        success_message = "パスキー「#{@passkey.label}」を登録しました。"

        respond_to do |format|
          format.html do
            flash[:success] = success_message
            if params[:first_time] == 'true'
              redirect_to root_path, notice: "パスキー認証の設定が完了しました！これでより安全にログインできます。"
            else
              redirect_to passkeys_path
            end
          end
          format.json do
            redirect_url = params[:first_time] == 'true' ? root_path : passkeys_path
            render json: {
              success: true,
              message: success_message,
              redirect_url: redirect_url
            }
          end
        end
      else
        error_message = "パスキーの登録に失敗しました: #{@passkey.errors.full_messages.join(', ')}"
        @webauthn_options = generate_webauthn_options
        @default_device_name = default_device_name

        respond_to do |format|
          format.html do
            flash.now[:error] = error_message
            render :new, status: :unprocessable_entity
          end
          format.json do
            render json: { error: error_message }, status: :unprocessable_entity
          end
        end
      end

    rescue JSON::ParserError
      error_message = "認証データの形式が正しくありません。"
      handle_error(error_message, :unprocessable_entity)
    rescue WebAuthn::Error => e
      Rails.logger.error "WebAuthn verification failed: #{e.message}"
      error_message = "パスキー認証に失敗しました。再度お試しください。"
      handle_error(error_message, :unprocessable_entity)
    rescue => e
      Rails.logger.error "Passkey registration failed: #{e.class} - #{e.message}"
      Rails.logger.error e.backtrace.join("\n")
      error_message = "パスキーの登録中にエラーが発生しました。"
      handle_error(error_message, :internal_server_error)
    end
  end

  def destroy
    if @passkey.destroy
      flash[:success] = "パスキー「#{@passkey.label}」を削除しました。"
    else
      flash[:error] = "パスキーの削除に失敗しました。"
    end
    redirect_to passkeys_path
  end

  private

  def set_passkey
    @passkey = current_user.passkeys.find(params[:id])
  end

  def passkey_params
    params.require(:passkey).permit(:label, credential: {})
  end

  def default_device_name
    user_agent = request.user_agent.to_s.downcase

    case user_agent
    when /iphone/
      "iPhone"
    when /ipad/
      "iPad"
    when /android/
      "Android端末"
    when /macintosh|mac os x/
      "Mac"
    when /windows/
      "Windows PC"
    when /linux/
      "Linux PC"
    else
      "パスキー対応デバイス"
    end
  end

  def generate_webauthn_options
    # WebAuthn registration options を生成
    # ユーザーIDを32バイト以下に制限
    user_id = generate_compact_user_id

    options = WebAuthn::Credential.options_for_create(
      user: {
        id: user_id,
        name: current_user.email,
        display_name: current_user.name
      },
      rp: {
        id: request.host == 'localhost' ? 'localhost' : request.host,
        name: 'BrightTalk'
      },
      authenticator_selection: {
        authenticator_attachment: 'platform',
        user_verification: 'preferred'
      }
    )

    # セッションにチャレンジを保存
    session[:creation_challenge] = options.challenge

    # デバッグログで構造を確認
    Rails.logger.info "WebAuthn options structure:"
    Rails.logger.info "Generated user_id length: #{user_id.bytesize} bytes"
    Rails.logger.info "RP: #{options.rp.class} - #{options.rp.inspect}"
    Rails.logger.info "User: #{options.user.class} - #{options.user.inspect}"
    Rails.logger.info "AuthenticatorSelection: #{options.authenticator_selection.class} - #{options.authenticator_selection.inspect}"

    # フロントエンド用にシリアライズ（ハッシュとオブジェクト両対応）
    {
      challenge: Base64.urlsafe_encode64(options.challenge, padding: false),
      rp: {
        id: get_value(options.rp, :id),
        name: get_value(options.rp, :name)
      },
      user: {
        id: Base64.urlsafe_encode64(get_value(options.user, :id), padding: false),
        name: get_value(options.user, :name),
        displayName: get_value(options.user, :display_name)
      },
      pubKeyCredParams: options.pub_key_cred_params.map(&:to_h),
      authenticatorSelection: {
        authenticatorAttachment: get_value(options.authenticator_selection, :authenticator_attachment),
        userVerification: get_value(options.authenticator_selection, :user_verification)
      },
      timeout: options.timeout,
      attestation: options.attestation,
      excludeCredentials: []
    }
  end

  private

  def verify_and_store_credential
    credential_data = params[:passkey][:credential]

    Rails.logger.info "Received credential data: #{credential_data.inspect}"
    Rails.logger.info "Session challenge: #{session[:creation_challenge].present? ? 'present' : 'missing'}"

    # セッションからチャレンジを取得
    stored_challenge = session[:creation_challenge]

    if stored_challenge.blank?
      raise StandardError, "登録チャレンジが見つかりません。再度お試しください。"
    end

    # WebAuthnの期待する形式に変換
    webauthn_credential_data = {
      "type" => credential_data[:type],
      "id" => credential_data[:id],
      "rawId" => credential_data[:rawId],
      "response" => {
        "clientDataJSON" => credential_data[:response][:clientDataJSON],
        "attestationObject" => credential_data[:response][:attestationObject]
      }
    }

    Rails.logger.info "Formatted WebAuthn credential data: #{webauthn_credential_data.inspect}"

    # WebAuthn credential を検証（正しい引数で呼び出し）
    webauthn_credential = WebAuthn::Credential.from_create(webauthn_credential_data)

    # チャレンジを検証
    webauthn_credential.verify(
      stored_challenge,
      origin: "#{request.scheme}://#{request.host_with_port}",
      rp_id: request.host == 'localhost' ? 'localhost' : request.host
    )

    Rails.logger.info "WebAuthn credential verification successful"

    # 一意性チェック
    existing_passkey = Passkey.find_by(
      identifier: Passkey.normalize_identifier(webauthn_credential.id)
    )

    if existing_passkey
      raise StandardError, "このパスキーは既に登録されています"
    end

    # セッションからチャレンジを削除
    session.delete(:creation_challenge)

    # WebAuthnCredential相当のオブジェクトを作成
    stored_credential = OpenStruct.new(
      external_id: webauthn_credential.id,
      public_key: webauthn_credential.public_key,
      sign_count: webauthn_credential.sign_count
    )

    [webauthn_credential, stored_credential]

  rescue WebAuthn::Error => e
    Rails.logger.error "WebAuthn verification failed: #{e.message}"
    Rails.logger.error "WebAuthn error backtrace: #{e.backtrace.join("\n")}"
    raise StandardError, "パスキー認証に失敗しました: #{e.message}"
  rescue => e
    Rails.logger.error "Unexpected error in verify_and_store_credential: #{e.class} - #{e.message}"
    Rails.logger.error "Error backtrace: #{e.backtrace.join("\n")}"
    raise
  end

  def handle_error(message, status)
    @webauthn_options = generate_webauthn_options
    @default_device_name = default_device_name

    respond_to do |format|
      format.html do
        flash.now[:error] = message
        render :new, status: status
      end
      format.json do
        render json: { error: message }, status: status
      end
    end
  end

  # ハッシュまたはオブジェクトから安全に値を取得するヘルパーメソッド
  def get_value(obj, key)
    case obj
    when Hash
      obj[key] || obj[key.to_s]
    else
      obj.respond_to?(key) ? obj.send(key) : nil
    end
  end

  # 64バイト制限を満たすコンパクトなユーザーIDを生成
  def generate_compact_user_id
    # ユーザーIDとタイムスタンプを組み合わせて32バイトのハッシュを生成
    data = "user_#{current_user.id}_#{Time.current.to_i}"
    digest = Digest::SHA256.digest(data)

    # SHA256ハッシュの最初の32バイトを使用（64バイト制限内）
    user_id = digest[0, 32]

    Rails.logger.info "Generated user_id for user #{current_user.id}: #{user_id.bytesize} bytes"

    user_id
  end

end