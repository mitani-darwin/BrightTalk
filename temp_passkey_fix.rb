# パスキー登録時のパスワード変更メール送信を無効化する修正

# User.transaction do の内容を以下に変更:
User.transaction do
  # 一時パスワードを生成して設定（後で削除）
  temp_password = "Temp#{SecureRandom.hex(8)}@#{rand(100..999)}"
  
  @user = User.create!(
    name: @pending_user_data['name'],
    email: @pending_user_data['email'],
    password: temp_password
  )

  # パスキー登録では確認メールを送信せず、自動で確認済み状態にする
  @user.confirm!
  Rails.logger.info "User email automatically confirmed for passkey registration: #{@user.email}"
  
  # パスキーを保存
  passkey = @user.webauthn_credentials.create!(
    external_id: credential_params[:id],
    public_key: webauthn_credential.public_key,
    nickname: params[:nickname] || "メインパスキー",
    sign_count: webauthn_credential.sign_count
  )
  
  # 一時パスワードを削? パスキー登録時のパスワード変更メール送信を無?
# User.transaction do の内容を以下に変更:
User.transaction do
  # 一時パwitUser.transaction do
  # 一時パスワードを?user.email}"
end
