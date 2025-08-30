require 'mail/ses'

ActiveSupport.on_load(:action_mailer) do
  def self.configure_aws_ses(environment)
    # デバッグ情報を出力
    puts "🔍 [DEBUG] Environment: #{environment}"
    puts "🔍 [DEBUG] Rails.env: #{Rails.env}"
    
    # Rails credentialsから試行
    aws_config = Rails.application.credentials.dig(:aws, environment.to_sym)
    
    # 認証情報の取得優先順位: Rails credentials → 環境変数
    if aws_config&.dig(:access_key_id) && aws_config&.dig(:secret_access_key)
      access_key_id = aws_config[:access_key_id]
      secret_access_key = aws_config[:secret_access_key]
      region = aws_config[:region] || ENV['AWS_REGION'] || 'ap-northeast-1'
      auth_source = 'Rails credentials'
      puts "🔑 [AUTH] Using Rails credentials for AWS authentication"
    else
      # 環境変数から読み込み（Kamal対応）
      access_key_id = ENV['AWS_ACCESS_KEY_ID']
      secret_access_key = ENV['AWS_SECRET_ACCESS_KEY']
      region = ENV['AWS_REGION'] || 'ap-northeast-1'
      auth_source = 'environment variables'
      puts "🔑 [AUTH] Rails credentials not available, trying environment variables"
    end

    # デバッグ情報
    puts "🔍 [DEBUG] Rails credentials available: #{aws_config ? 'Yes' : 'No'}"
    puts "🔍 [DEBUG] ENV AWS_ACCESS_KEY_ID present: #{ENV['AWS_ACCESS_KEY_ID'] ? 'Yes (***' + ENV['AWS_ACCESS_KEY_ID'][-4..-1] + ')' : 'No'}"
    puts "🔍 [DEBUG] ENV AWS_SECRET_ACCESS_KEY present: #{ENV['AWS_SECRET_ACCESS_KEY'] ? 'Yes (***' + ENV['AWS_SECRET_ACCESS_KEY'][-4..-1] + ')' : 'No'}"

    if access_key_id && secret_access_key
      ActionMailer::Base.add_delivery_method :ses, Mail::SES,
                                             region: region,
                                             access_key_id: access_key_id,
                                             secret_access_key: secret_access_key

      ActionMailer::Base.delivery_method = :ses
      ActionMailer::Base.perform_deliveries = true
      ActionMailer::Base.raise_delivery_errors = true

      # スパム対策ヘッダーの強化
      ActionMailer::Base.default(
        from: 'BrightTalk <noreply@brighttalk.jp>',
        reply_to: 'BrightTalk Support <support@brighttalk.jp>',

        # 配信停止リンク（必須）
        'List-Unsubscribe' => '<mailto:unsubscribe@brighttalk.jp>, <https://brighttalk.jp/unsubscribe>',
        'List-Unsubscribe-Post' => 'List-Unsubscribe=One-Click',

        # スパム対策ヘッダー
        'X-Mailer' => 'BrightTalk/1.0',
        'X-Priority' => '3',
        'X-MSMail-Priority' => 'Normal',
        'Importance' => 'Normal',
        'Precedence' => 'bulk',

        # メール分類（トランザクションメール）
        'X-MC-Tags' => 'transactional,user-authentication',
        'X-Category' => 'transactional',
        'X-Classification' => 'system-notification',

        # 自動応答抑制
        'X-Auto-Response-Suppress' => 'OOF, DR, RN, NRN, AutoReply',

        # 信頼性向上
        'Organization' => 'BrightTalk Community Platform',
        'X-Originating-IP' => '[AWS SES]',

        # メッセージID（独自ドメイン使用）
        'Message-ID' => -> { "<#{SecureRandom.uuid}@mail.brighttalk.jp>" }
      )

      # メール送信前の検証とマルチパート強制（修正版）
      ActionMailer::Base.register_interceptor(
        Class.new do
          def self.delivering_email(message)
            # マルチパート形式を強制
            ensure_multipart_format(message)
            validate_spam_score(message)
            log_email_details(message)
          end

          private

          def self.ensure_multipart_format(message)
            # HTMLメールを検出してマルチパート化
            if message.content_type&.start_with?('text/html') && !message.multipart?
              Rails.logger.info "🔄 [MULTIPART] HTMLのみのメールを検出 - マルチパート化します"

              # 既存のHTMLコンテンツを保存
              html_content = message.body.to_s

              # テキスト版を自動生成
              text_content = html_to_text(html_content)

              # メールを完全にリセット
              message.body = nil
              message.content_type = nil

              # テキストパートを追加
              message.text_part = Mail::Part.new do
                content_type 'text/plain; charset=UTF-8'
                body text_content
              end

              # HTMLパートを追加
              message.html_part = Mail::Part.new do
                content_type 'text/html; charset=UTF-8'
                body html_content
              end

              Rails.logger.info "✅ [MULTIPART] マルチパート化完了"
              Rails.logger.info "📧 Content-Type: #{message.content_type}"
            end
          end

          def self.html_to_text(html)
            # HTMLからテキストへの変換（改良版）
            text = html.dup

            # ボタンリンクの変換（改良版）
            text = text.gsub(/<a[^>]*href=["']([^"']*)["'][^>]*>([^<]*)<\/a>/i, '\2: \1')

            # 見出しの変換
            text = text.gsub(/<h[1-6][^>]*>([^<]*)<\/h[1-6]>/i, "\n\n\1\n" + ("=" * 20) + "\n")

            # 改行の処理
            text = text.gsub(/<br\s*\/?>/i, "\n")
            text = text.gsub(/<\/p>/i, "\n\n")
            text = text.gsub(/<\/div>/i, "\n")
            text = text.gsub(/<\/td>/i, "\t")
            text = text.gsub(/<\/tr>/i, "\n")
            text = text.gsub(/<\/li>/i, "\n")

            # リストアイテムの処理
            text = text.gsub(/<li[^>]*>/i, "• ")

            # HTMLタグの除去
            text = text.gsub(/<[^>]+>/, '')

            # HTMLエンティティの変換
            text = text.gsub(/&nbsp;/, ' ')
            text = text.gsub(/&amp;/, '&')
            text = text.gsub(/&lt;/, '<')
            text = text.gsub(/&gt;/, '>')
            text = text.gsub(/&quot;/, '"')
            text = text.gsub(/&#39;/, "'")
            text = text.gsub(/&hellip;/, '...')

            # スペースと改行の整理
            text = text.gsub(/[ \t]+/, ' ')           # 複数スペースを1つに
            text = text.gsub(/\n[ \t]+/, "\n")       # 行頭のスペース削除
            text = text.gsub(/[ \t]+\n/, "\n")       # 行末のスペース削除
            text = text.gsub(/\n{3,}/, "\n\n")       # 3つ以上の改行を2つに
            text = text.strip

            text
          end

          def self.validate_spam_score(message)
            # 件名の検証
            subject = message.subject
            if spam_prone_subject?(subject)
              Rails.logger.warn "⚠️ [SPAM CHECK] 件名にスパム要素が含まれています: #{subject}"
            end

            # HTML/テキスト比率の検証
            if message.multipart?
              html_part = message.html_part&.body&.to_s
              text_part = message.text_part&.body&.to_s

              if html_part && text_part
                html_length = html_part.length
                text_length = text_part.length
                ratio = html_length.to_f / text_length if text_length > 0

                Rails.logger.info "📊 [SPAM CHECK] HTML/テキスト比率: #{ratio ? ratio.round(2) : 'N/A'}"

                if ratio && ratio > 3.0
                  Rails.logger.warn "⚠️ [SPAM CHECK] HTML/テキスト比率が高すぎます: #{ratio.round(2)}"
                end
              end
            end
          end

          def self.spam_prone_subject?(subject)
            spam_keywords = [
              /無料/i, /緊急/i, /今すぐ/i, /クリック/i,
              /お得/i, /限定/i, /特別/i, /キャンペーン/i,
              /！{2,}/, /\${2,}/, /\*{3,}/
            ]
            spam_keywords.any? { |pattern| subject.match?(pattern) }
          end

          def self.log_email_details(message)
            Rails.logger.info "🚀 [MAIL INTERCEPTOR] メール送信開始"
            Rails.logger.info "📧 宛先: #{message.to.join(', ')}"
            Rails.logger.info "📧 件名: #{message.subject}"
            Rails.logger.info "📧 送信者: #{message.from.join(', ')}"
            Rails.logger.info "📧 Message-ID: #{message.message_id}"
            Rails.logger.info "📧 Content-Type: #{message.content_type}"
            Rails.logger.info "📧 マルチパート: #{message.multipart?}"

            if message.multipart?
              Rails.logger.info "📧 HTMLパート: #{message.html_part ? 'あり (' + message.html_part.body.to_s.length.to_s + '文字)' : 'なし'}"
              Rails.logger.info "📧 テキストパート: #{message.text_part ? 'あり (' + message.text_part.body.to_s.length.to_s + '文字)' : 'なし'}"
            end
          end
        end
      )

      puts "✅ AWS SES configured for #{environment} environment"
      puts "🔑 Using #{auth_source} for AWS authentication"
      puts "🌏 Region: #{region}"
      return true
    else
      puts "❌ AWS credentials not found for #{environment} environment"
      puts "💡 Available sources checked:"
      puts "   - Rails credentials: #{aws_config ? 'Found but incomplete' : 'Not found'}"
      puts "   - Environment variables: AWS_ACCESS_KEY_ID=#{ENV['AWS_ACCESS_KEY_ID'] ? 'Set' : 'Not set'}, AWS_SECRET_ACCESS_KEY=#{ENV['AWS_SECRET_ACCESS_KEY'] ? 'Set' : 'Not set'}"
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