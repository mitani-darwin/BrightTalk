# config/initializers/active_storage_direct_upload.rb
Rails.application.config.to_prepare do
  ActiveStorage::DirectUploadsController.class_eval do
    skip_before_action :verify_authenticity_token

    # 大容量ファイル対応
    before_action :set_request_timeout

    # 日本語ファイル名対応
    before_action :set_utf8_encoding

    # デバッグログ追加
    before_action :log_upload_request, if: -> { Rails.env.development? }

    private

    def set_request_timeout
      request.env['rack.timeout.service_timeout'] = 300 if defined?(Rack::Timeout)
    end

    def set_utf8_encoding
      request.headers['Accept-Charset'] = 'UTF-8'
      response.headers['Content-Type'] = 'application/json; charset=utf-8'
    end

    def log_upload_request
      Rails.logger.info "Direct Upload Request: #{params.inspect}"
      Rails.logger.info "Request headers: #{request.headers.to_h.select { |k,v| k.start_with?('HTTP_') }.inspect}"
    end
  end
end