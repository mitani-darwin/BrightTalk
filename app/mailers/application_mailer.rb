class ApplicationMailer < ActionMailer::Base
  # AWS SESの設定から送信者アドレスを取得
  default from: proc {
    aws_config = Rails.application.credentials.dig(:aws, Rails.env.to_sym)
    if aws_config&.dig(:from_email)
      aws_config[:from_email]
    else
      Rails.env.production? ? 'noreply@brighttalk.jp' : 'dev-noreply@brighttalk.jp'
    end
  }

  layout 'mailer'
end