
# config/initializers/aws_ses.rb
if Rails.env.development? || Rails.env.production?
  # 開発環境は :development キー、本番環境は :production キーを使用
  env_key = Rails.env.to_sym
  aws_config = Rails.application.credentials.dig(:aws, env_key) || Rails.application.credentials.aws

  if aws_config
    require 'aws-sdk-ses'

    Aws.config.update({
                        region: aws_config[:region] || 'us-east-1',
                        credentials: Aws::Credentials.new(
                          aws_config[:access_key_id],
                          aws_config[:secret_access_key]
                        )
                      })

    Rails.logger.info "AWS SES configured for #{Rails.env} environment with region: #{aws_config[:region] || 'us-east-1'}"
  else
    Rails.logger.warn "AWS SES configuration not found for #{Rails.env} environment"
  end
end