
# frozen_string_literal: true

class Users::ConfirmationsController < Devise::ConfirmationsController
  # GET /resource/confirmation?confirmation_token=abcdef
  def show
    self.resource = resource_class.confirm_by_token(params[:confirmation_token])
    yield resource if block_given?

    if resource.errors.empty?
      # マジックリンクとして自動ログイン
      sign_in(resource)
      set_flash_message!(:notice, :confirmed)
      flash[:notice] = "メールアドレスの確認が完了し、ログインしました！"
      respond_with_navigational(resource){ redirect_to after_confirmation_path_for(resource_name, resource) }
    else
      flash[:alert] = "確認リンクが無効または期限切れです。再度登録をお試しください。"
      respond_with_navigational(resource.errors, status: :unprocessable_entity){ render :new }
    end
  end

  protected

  def after_confirmation_path_for(resource_name, resource)
    # メール確認完了後、WebAuthn設定画面にリダイレクト
    sign_in(resource)
    new_webauthn_credential_path
  end

end