require 'mail/ses'

# ActiveSupport.on_loadを使用して、ActionMailerが完全に初期化された後に設定
ActiveSupport.on_load(:action_mailer) do
  # AWS SES設定の初期化
  def self.configure_aws_ses(environment)
    aws_config = Rails.application.credentials.dig(:aws, environment.to_sym)

    if aws_config&.dig(:access_key_id) && aws_config&.dig(:secret_access_key)
      # SES delivery methodを登録
      ActionMailer::Base.add_delivery_method :ses, Mail::SES,
                                             region: aws_config[:region] || 'ap-northeast-1',
                                             access_key_id: aws_config[:access_key_id],
                                             secret_access_key: aws_config[:secret_access_key]

      # 設定を適用
      ActionMailer::Base.delivery_method = :ses
      ActionMailer::Base.perform_deliveries = true
      ActionMailer::Base.raise_delivery_errors = true

      # デフォルト送信者アドレスの設定
      default_from = aws_config[:from_email] ||
                     (environment.to_s == 'production' ? 'noreply@brighttalk.jp' : 'dev-noreply@brighttalk.jp')

      ActionMailer::Base.default from: default_from

      puts "✅ AWS SES configured for #{environment} environment"
      puts "   Region: #{aws_config[:region] || 'ap-northeast-1'}"
      puts "   From Email: #{default_from}"
      puts "   Delivery Method: :ses"

      return true
    else
      puts "❌ AWS credentials not found for #{environment} environment"
      return false
    end
  end

  # 環境別設定
  case Rails.env
  when 'development'
    unless configure_aws_ses('development')
      # AWS認証情報がない場合は、テストモードにフォールバック
      ActionMailer::Base.delivery_method = :test
      ActionMailer::Base.perform_deliveries = false
      puts "🔄 Falling back to test mode for development"
    end

  when 'production'
    unless configure_aws_ses('production')
      raise "AWS SES credentials are required for production environment"
    end

  when 'test'
    ActionMailer::Base.delivery_method = :test
    ActionMailer::Base.perform_deliveries = false
  end
end