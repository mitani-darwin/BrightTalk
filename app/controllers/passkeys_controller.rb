class PasskeysController < ApplicationController
  before_action :authenticate_user!
  before_action :set_passkey, only: [:show, :destroy]

  def index
    @passkeys = current_user.passkeys.order(:created_at)
  end

  def new
    @first_time = params[:first_time] == 'true'

    # WebAuthn registration options を生成
    @webauthn_options = generate_webauthn_options
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

        flash[:success] = "パスキー「#{@passkey.label}」を登録しました。"

        if params[:first_time] == 'true'
          redirect_to root_path, notice: "パスキー認証の設定が完了しました！これでより安全にログインできます。"
        else
          redirect_to passkeys_path
        end
      else
        flash.now[:error] = "パスキーの登録に失敗しました: #{@passkey.errors.full_messages.join(', ')}"
        @webauthn_options = generate_webauthn_options
        render :new, status: :unprocessable_entity
      end

    rescue JSON::ParserError
      flash.now[:error] = "認証データの形式が正しくありません。"
      @webauthn_options = generate_webauthn_options
      render :new, status: :unprocessable_entity
    rescue WebAuthn::Error => e
      Rails.logger.error "WebAuthn verification failed: #{e.message}"
      flash.now[:error] = "パスキー認証に失敗しました。再度お試しください。"
      @webauthn_options = generate_webauthn_options
      render :new, status: :unprocessable_entity
    rescue => e
      Rails.logger.error "Passkey registration failed: #{e.class} - #{e.message}"
      Rails.logger.error e.backtrace.join("\n")
      flash.now[:error] = "パスキーの登録中にエラーが発生しました。"
      @webauthn_options = generate_webauthn_options
      render :new, status: :unprocessable_entity
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
    params.permit(:label, :credential)
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
    options = WebAuthn::Credential.options_for_registration(
      user: {
        id: WebAuthn.generate_user_id,
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

    # フロントエンド用にシリアライズ
    {
      challenge: Base64.urlsafe_encode64(options.challenge, padding: false),
      rp: options.rp,
      user: {
        id: Base64.urlsafe_encode64(options.user[:id], padding: false),
        name: options.user[:name],
        displayName: options.user[:display_name]
      },
      pubKeyCredParams: options.pub_key_cred_params.map(&:to_h),
      authenticatorSelection: options.authenticator_selection,
      timeout: options.timeout,
      attestation: options.attestation
    }
  end

  def verify_and_store_credential
    credential_params = JSON.parse(params[:credential])

    # WebAuthn credential を検証
    webauthn_credential = WebAuthn::Credential.from_registration(
      credential_params,
      session[:creation_challenge],
      origin: "#{request.scheme}://#{request.host_with_port}",
      rp_id: request.host == 'localhost' ? 'localhost' : request.host
    )

    # 検証成功 - 一意性チェック
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
  end
end