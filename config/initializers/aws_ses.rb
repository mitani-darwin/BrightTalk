
require 'mail/ses'

ActiveSupport.on_load(:action_mailer) do
  def self.configure_aws_ses(environment)
    aws_config = Rails.application.credentials.dig(:aws, environment.to_sym)

    if aws_config&.dig(:access_key_id) && aws_config&.dig(:secret_access_key)
      # SES delivery methodを登録
      ActionMailer::Base.add_delivery_method :ses, Mail::SES,
                                             region: aws_config[:region] || 'ap-northeast-1',
                                             access_key_id: aws_config[:access_key_id],
                                             secret_access_key: aws_config[:secret_access_key]

      ActionMailer::Base.delivery_method = :ses
      ActionMailer::Base.perform_deliveries = true
      ActionMailer::Base.raise_delivery_errors = true

      # デフォルト設定の改善（スパム対策強化）
      ActionMailer::Base.default(
        from: 'BrightTalk <noreply@brighttalk.jp>',
        reply_to: 'BrightTalk Support <support@brighttalk.jp>',
        # List-Unsubscribe を1つのヘッダーにまとめる
        'List-Unsubscribe' => '<mailto:unsubscribe@brighttalk.jp>, <https://brighttalk.jp/unsubscribe>',
        'List-Unsubscribe-Post' => 'List-Unsubscribe=One-Click',
        # スパム対策ヘッダーの追加
        'X-Mailer' => 'BrightTalk Application v1.0',
        'X-Auto-Response-Suppress' => 'OOF, DR, RN, NRN',
        'Precedence' => 'bulk',
        # 優先度を設定
        'X-Priority' => '3',
        'X-MSMail-Priority' => 'Normal',
        'Importance' => 'Normal',
        # 分類ヘッダー
        'X-Category' => 'transactional',
        # Content-Type の明示的設定
        'Content-Type' => 'text/html; charset=UTF-8',
        # メッセージIDの改善（mail.サブドメインを使用）
        'Message-ID' => -> { "<#{SecureRandom.uuid}@mail.brighttalk.jp>" }
      )

      puts "✅ AWS SES configured for #{environment} environment"
      return true
    else
      puts "❌ AWS credentials not found for #{environment} environment"
      return false
    end
  end

  case Rails.env
  when 'development'
    unless configure_aws_ses('development')
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