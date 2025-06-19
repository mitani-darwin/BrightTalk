
class Users::ConfirmationsController < Devise::ConfirmationsController
  # GET /resource/confirmation?confirmation_token=abcdef
  def show
    self.resource = resource_class.confirm_by_token(params[:confirmation_token])
    yield resource if block_given?

    if resource.errors.empty?
      set_flash_message!(:notice, :confirmed)

      # ユーザーを自動的にログインさせる
      sign_in(resource)

      # WebAuthnが利用可能かチェック
      if webauthn_available?
        # WebAuthn登録にリダイレクト
        redirect_to new_webauthn_credential_path(first_time: true)
      else
        # WebAuthnが利用できない場合はホームページへ
        redirect_to root_path, notice: 'アカウントが確認されました。ログインしました。'
      end
    else
      respond_with(resource)
    end
  end

  private

  def after_confirmation_path_for(resource_name, resource)
    # WebAuthnが利用可能な場合はWebAuthn登録画面へ
    if webauthn_available?
      new_webauthn_credential_path(first_time: true)
    else
      root_path
    end
  end

  def webauthn_available?
    # JavaScriptでWebAuthn APIの利用可能性をチェックするため、
    # サーバーサイドでは常にtrueを返し、フロントエンドで判定する
    true
  end
end