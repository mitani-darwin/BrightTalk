class ApplicationMailer < ActionMailer::Base
  default from: "BrightTalk <noreply@brighttalk.jp>"
  layout "mailer"

  # マルチパート形式の強制
  def multipart_mail(options = {})
    # HTMLとテキストの両方のテンプレートが存在することを確認
    template_name = options[:template_name] || action_name
    template_path = options[:template_path] || self.class.mailer_name

    html_template_exists = template_exists?(template_name, template_path, "html")
    text_template_exists = template_exists?(template_name, template_path, "text")

    if html_template_exists && text_template_exists
      # 両方のテンプレートが存在する場合、Railsが自動的にマルチパートメールを作成
      mail(options)
    elsif html_template_exists
      # HTMLテンプレートのみの場合、テキスト版を自動生成してマルチパート化
      Rails.logger.info "📧 [MULTIPART] テキストテンプレートが見つからないため、HTMLから自動生成します"
      mail(options)
    else
      # テキストテンプレートのみの場合はそのまま
      mail(options)
    end
  end

  private

  def template_exists?(template_name, template_path, format)
    lookup_context.exists?(template_name, template_path, false, [], format: format)
  end
end
