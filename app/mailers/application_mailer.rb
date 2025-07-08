class ApplicationMailer < ActionMailer::Base
  default from: Rails.application.config.action_mailer.default_options&.dig(:from) || 'noreply@brighttalk.jp'
  layout 'mailer'
end