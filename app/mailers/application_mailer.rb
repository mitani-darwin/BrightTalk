class ApplicationMailer < ActionMailer::Base
  default from: Rails.application.credentials.aws[:ses][:from_email]
  layout 'mailer'
end