class Users::ConfirmationsController < Devise::ConfirmationsController
  before_action :log_user_status

  def show
    Rails.logger.info "Confirmation started with token: #{params[:confirmation_token]}"

    # 元のconfirmationロジックを実行
    self.resource = resource_class.confirm_by_token(params[:confirmation_token])
    yield resource if block_given?

    if resource.errors.empty?
      set_flash_message!(:notice, :confirmed)
      Rails.logger.info "User #{resource.id} confirmed successfully"

      # ユーザーをサインイン
      sign_in(resource_name, resource)
      Rails.logger.info "User #{resource.id} signed in after confirmation"

      # セッションから仮登録情報を削除
      session.delete(:pending_user_id)

      # シンプルにホームページにリダイレクト
      Rails.logger.info "Redirecting to home for confirmed user: #{resource.id}"
      redirect_to root_path, notice: "メール認証が完了し、ログインしました。"
    else
      Rails.logger.error "Confirmation failed for token #{params[:confirmation_token]}: #{resource.errors.full_messages}"
      respond_with(resource)
    end
  end

  private

  def after_confirmation_path_for(resource_name, resource)
    root_path
  end

  def log_user_status
    Rails.logger.info "=== User Status Debug ==="
    Rails.logger.info "Controller: #{self.class.name}##{action_name}"
    Rails.logger.info "Current user: #{current_user&.email || 'none'}"
    Rails.logger.info "User signed in?: #{user_signed_in?}"
    Rails.logger.info "Session ID: #{session.id}"
    Rails.logger.info "=========================="
  end
end
