module ApplicationHelper
  # Deviseの代わりに独自の認証システム用のヘルパーメソッドを追加
  def user_signed_in?
    logged_in?
  end

  def authenticate_user!
    require_login
  end
end