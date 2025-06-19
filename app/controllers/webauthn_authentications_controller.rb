
class WebauthnAuthenticationsController < ApplicationController
  # ログイン済みユーザーは除外しない（WebAuthn認証のため）
  skip_before_action :authenticate_user!

  def new
    # JSONリクエストの場合のパラメータ取得を修正
    email = params[:email] ||
            params.dig(:webauthn_authentication, :email) ||
            session[:webauthn_email]

    # POSTリクエストの場合、メールアドレスをセッションに保存
    if request.post? && email.present?
      session[:webauthn_email] = email
    end

    # メールアドレスが無い場合は、ログイン画面にリダイレクト
    if email.blank?
      respond_to do |format|
        format.html { redirect_to new_user_session_path, alert: 'メールアドレスを指定してください。' }
        format.json { render json: { error: 'メールアドレスが必要です' }, status: :bad_request }
      end
      return
    end

    user = User.find_by(email: email)

    # ユーザーが存在しない場合
    unless user
      respond_to do |format|
        format.html { redirect_to new_user_session_path, alert: 'アカウントが見つかりません。' }
        format.json { render json: { error: 'アカウントが見つかりません' }, status: :not_found }
      end
      return
    end

    # ユーザーが未確認の場合
    unless user.confirmed?
      respond_to do |format|
        format.html { redirect_to new_user_session_path, alert: 'アカウントが未確認です。確認メールをご確認ください。' }
        format.json { render json: { error: 'アカウントが未確認です' }, status: :unauthorized }
      end
      return
    end

    # WebAuthn有効性チェック
    unless user.webauthn_enabled && user.webauthn_credentials.any?
      respond_to do |format|
        format.html { redirect_to new_user_session_path, alert: 'WebAuthn認証が利用できません。パスワードでログインしてください。' }
        format.json { render json: { error: 'WebAuthn認証が利用できません' }, status: :forbidden }
      end
      return
    end

    # セッションにメールアドレスを保存（既に保存されていても再度保存）
    session[:webauthn_email] = email

    begin
      # WebAuthn認証オプションを生成
      webauthn_options = WebAuthn::Credential.options_for_get(
        allow: [] # 空配列にして、すべての認証器を許可
      )

      # セッションにチャレンジを保存
      session[:authentication_challenge] = webauthn_options.challenge

      webauthn_response = {
        challenge: Base64.urlsafe_encode64(webauthn_options.challenge, padding: false),
        allowCredentials: [], # Touch IDなどの内蔵認証器を使用するため空にする
        timeout: webauthn_options.timeout,
        userVerification: 'required' # Touch IDを強制するため必須に設定
      }

      Rails.logger.info "WebAuthn authentication options generated for #{email}: #{webauthn_response.inspect}"

      render json: webauthn_response

    rescue => e
      Rails.logger.error "WebAuthn authentication options generation failed: #{e.message}"
      Rails.logger.error e.backtrace
      respond_to do |format|
        format.html { redirect_to new_user_session_path, alert: 'WebAuthn認証の準備でエラーが発生しました。' }
        format.json { render json: { error: 'WebAuthn認証の準備でエラーが発生しました' }, status: :internal_server_error }
      end
    end
  end

  def create
    email = session[:webauthn_email]

    unless email
      respond_to do |format|
        format.html { redirect_to new_user_session_path, alert: 'セッションが無効です。再度ログインしてください。' }
        format.json { render json: { error: 'セッションが無効です' }, status: :unauthorized }
      end
      return
    end

    user = User.find_by(email: email)
    unless user
      respond_to do |format|
        format.html { redirect_to new_user_session_path, alert: 'ユーザーが見つかりません。' }
        format.json { render json: { error: 'ユーザーが見つかりません' }, status: :not_found }
      end
      return
    end

    begin
      Rails.logger.info "WebAuthn authentication request received"
      Rails.logger.info "Full params: #{params.inspect}"
      Rails.logger.info "Authentication params: #{authentication_params.inspect}"

      # WebAuthn認証データを検証
      webauthn_credential = WebAuthn::Credential.from_get(authentication_params)

      # データベースから対応する認証情報を取得
      stored_credential = user.webauthn_credentials.find_by(external_id: webauthn_credential.id)

      unless stored_credential
        Rails.logger.error "WebAuthn credential not found: #{webauthn_credential.id}"
        respond_to do |format|
          format.html { redirect_to new_user_session_path, alert: '認証キーが見つかりません。' }
          format.json { render json: { error: '認証キーが見つかりません' }, status: :not_found }
        end
        return
      end

      # 認証を検証
      webauthn_credential.verify(
        session[:authentication_challenge],
        public_key: stored_credential.public_key,
        sign_count: stored_credential.sign_count
      )

      # サインカウントを更新
      stored_credential.update!(sign_count: webauthn_credential.sign_count)

      # ユーザーをログインさせる
      sign_in(user)

      # セッションをクリア
      session.delete(:authentication_challenge)
      session.delete(:webauthn_email)

      Rails.logger.info "WebAuthn authentication successful for user: #{user.email}"

      respond_to do |format|
        format.html { redirect_to root_path, notice: 'WebAuthn認証でログインしました。' }
        format.json { render json: { success: true, message: 'WebAuthn認証でログインしました', redirect_url: root_path } }
      end

    rescue WebAuthn::Error => e
      Rails.logger.error "WebAuthn authentication failed: #{e.message}"
      Rails.logger.error e.backtrace
      respond_to do |format|
        format.html { redirect_to new_user_session_path, alert: 'WebAuthn認証に失敗しました。' }
        format.json { render json: { error: 'WebAuthn認証に失敗しました' }, status: :unauthorized }
      end
    rescue => e
      Rails.logger.error "Unexpected error during WebAuthn authentication: #{e.message}"
      Rails.logger.error e.backtrace
      respond_to do |format|
        format.html { redirect_to new_user_session_path, alert: '予期しないエラーが発生しました。' }
        format.json { render json: { error: '予期しないエラーが発生しました' }, status: :internal_server_error }
      end
    end
  end

  private

  def authentication_params
    # JavaScriptから送信される credential オブジェクトの構造に合わせて修正
    if params[:credential].present?
      credential_data = params.require(:credential).permit(
        :id,
        :rawId,
        :type,
        response: [:clientDataJSON, :authenticatorData, :signature, :userHandle]
      )

      Rails.logger.info "Processed credential data: #{credential_data.inspect}"
      return credential_data
    else
      Rails.logger.error "No credential data found in params"
      raise ActionController::ParameterMissing.new(:credential)
    end
  end
end