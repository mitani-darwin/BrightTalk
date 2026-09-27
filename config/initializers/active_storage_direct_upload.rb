# config/initializers/active_storage_direct_upload.rb
Rails.application.config.to_prepare do
  ActiveStorage::DirectUploadsController.class_eval do
    # 直接アップロードで受け付ける形式と上限サイズ
    # S3 の署名付きアップロード URL には宣言したサイズと形式が含まれるため、宣言を偽って上限を超えることはできない
    const_set(:ALLOWED_CONTENT_TYPE_PREFIXES, %w[image/ video/].freeze) unless const_defined?(:ALLOWED_CONTENT_TYPE_PREFIXES)
    const_set(:MAX_BYTE_SIZE, 2.gigabytes) unless const_defined?(:MAX_BYTE_SIZE)

    # ApplicationController を継承しないため、ログイン必須をここで指定する
    # （未ログインでも本番の S3 にファイルを置けてしまうのを防ぐ）
    before_action :authenticate_user!
    before_action :validate_direct_upload_blob, only: :create

    # 大容量ファイル対応
    before_action :set_request_timeout

    # 日本語ファイル名対応
    before_action :set_utf8_encoding

    # デバッグログ追加
    before_action :log_upload_request, if: -> { Rails.env.development? }

    private

    def validate_direct_upload_blob
      blob = params.require(:blob)
      content_type = blob[:content_type].to_s
      byte_size = blob[:byte_size].to_i

      unless self.class::ALLOWED_CONTENT_TYPE_PREFIXES.any? { |prefix| content_type.start_with?(prefix) }
        render json: { error: "画像または動画のみアップロードできます" }, status: :unprocessable_entity
        return
      end

      unless byte_size.positive? && byte_size <= self.class::MAX_BYTE_SIZE
        render json: { error: "ファイルサイズは#{self.class::MAX_BYTE_SIZE / 1.gigabyte}GBまでです" }, status: :unprocessable_entity
      end
    end

    def set_request_timeout
      request.env["rack.timeout.service_timeout"] = 300 if defined?(Rack::Timeout)
    end

    def set_utf8_encoding
      request.headers["Accept-Charset"] = "UTF-8"
      response.headers["Content-Type"] = "application/json; charset=utf-8"
    end

    def log_upload_request
      Rails.logger.info "Direct Upload Request: #{params.inspect}"
      Rails.logger.info "Request headers: #{request.headers.to_h.select { |k, v| k.start_with?('HTTP_') }.inspect}"
    end
  end
end
