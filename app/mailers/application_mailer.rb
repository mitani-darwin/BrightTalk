class ApplicationMailer < ActionMailer::Base
  default from: Rails.application.credentials.dig(:aws, Rails.env.to_sym, :ses, :from_email) || 'noreply@example.com'
  layout 'mailer'
end