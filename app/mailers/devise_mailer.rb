class DeviseMailer < Devise::Mailer
  helper :application
  include Devise::Controllers::UrlHelpers
  default template_path: 'devise/mailer'

  def confirmation_instructions(record, token, opts={})
    @token = token
    @resource = record
    @email = record.email
    @user_name = record.name || record.email.split('@').first

    # スパム対策のためのヘッダー追加
    headers = {
      'X-MC-Subaccount' => 'user-authentication',
      'X-MC-Metadata' => {
        'user_id' => record.id,
        'email_type' => 'confirmation',
        'created_at' => Time.current.iso8601
      }.to_json
    }

    # マルチパート対応のメール送信
    mail(
      to: record.email,
      subject: '【BrightTalk】メールアドレスの確認をお願いします',
      headers: headers
    ) do |format|
      format.html { render 'confirmation_instructions' }
      format.text { render 'confirmation_instructions' }
    end
  end

  def reset_password_instructions(record, token, opts={})
    @token = token
    @resource = record
    @email = record.email
    @user_name = record.name || record.email.split('@').first

    headers = {
      'X-MC-Subaccount' => 'password-reset',
      'X-MC-Metadata' => {
        'user_id' => record.id,
        'email_type' => 'password_reset',
        'created_at' => Time.current.iso8601
      }.to_json
    }

    mail(
      to: record.email,
      subject: '【BrightTalk】パスワード再設定のご案内',
      headers: headers
    ) do |format|
      format.html { render 'reset_password_instructions' }
      format.text { render 'reset_password_instructions' }
    end
  end
end