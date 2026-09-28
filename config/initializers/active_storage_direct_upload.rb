# config/initializers/active_storage_direct_upload.rb
Rails.application.config.to_prepare do
  ActiveStorage::DirectUploadsController.class_eval do
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

      # 形式のみ制限し、サイズは制限しない
      # S3 の署名付きアップロード URL には宣言した形式が含まれるため、宣言を偽って別の形式を置くことはできない
      unless DirectUploadPolicy.allowed_content_type?(content_type)
        render json: { error: "画像または動画のみアップロードできます" }, status: :unprocessable_entity
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
