class PasskeyRegistrationsController < ApplicationController
  before_action :ensure_user_not_signed_in
  before_action :find_pending_user, only: [:register_passkey, :verify_passkey]

  def new
    @user = User.new
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
        format.html { redirect_to new_passkey_registration_path }
        format.json { 
          render json: {
            success: true,
            message: "基本情報を確認しました。パスキーを設定してください。"
          }
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
    temp_user_id = Digest::SHA256.hexdigest(@pending_user_data['email'])
    
    # WebAuthn登録オプション生成
    registration_options = {
      challenge: challenge,
      rp: {
        id: rp_id,
        name: "BrightTalk"
      },
      user: {
        id: Base64.urlsafe_encode64(temp_user_id),
        name: @pending_user_data['email'],
        displayName: @pending_user_data['name']
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
      
      credential_params = params.require(:credential)
      
      # WebAuthn認証情報を構築
      webauthn_credential = WebAuthn::Credential.from_create({
        id: credential_params[:id],
        rawId: credential_params[:rawId],
        type: credential_params[:type],
        response: {
          clientDataJSON: credential_params[:response][:clientDataJSON],
          attestationObject: credential_params[:response][:attestationObject]
        }
      })
      
      # パスキー登録を検証
      webauthn_credential.verify(challenge)
      
      # パスキー検証成功後にユーザーを作成
      User.transaction do
        # 一時パスワードを生成して設定（後で削除）
        temp_password = "Temp#{SecureRandom.hex(8)}@#{rand(100..999)}"
        
        @user = User.create!(
          name: @pending_user_data['name'],
          email: @pending_user_data['email'],
          password: temp_password
        )
        
        # パスキーを保存
        passkey = @user.webauthn_credentials.create!(
          external_id: credential_params[:id],
          public_key: webauthn_credential.public_key,
          nickname: params[:nickname] || "メインパスキー",
          sign_count: webauthn_credential.sign_count
        )
        
        # 一時パスワードを削除してパスキー認証のみにする
        @user.update!(encrypted_password: "")
      end
      
      # ユーザーをログインさせる
      sign_in(@user)
      
      # セッションをクリア
      session.delete(:passkey_registration_challenge)
      session.delete(:pending_user_data)
      
      Rails.logger.info "User created and passkey registration successful for user: #{@user.id}"
      
      render json: {
        success: true,
        message: "パスキー認証の設定が完了しました。",
        redirect_url: after_sign_up_path_for(@user)
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