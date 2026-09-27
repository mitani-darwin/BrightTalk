# 大きな動画を S3 へ分割アップロードするための窓口（ブラウザの MultipartUpload から呼ばれる）
# 開始時に発行するトークンに保存先とアップロード ID を署名して持たせ、本人以外が操作できないようにする
class MultipartUploadsController < ApplicationController
  TOKEN_PURPOSE = :multipart_upload
  TOKEN_EXPIRES_IN = 24.hours
  MAX_PART_URLS_PER_REQUEST = 100
  # MD5 を Base64 にしたもの（Active Storage の blob の checksum と同じ形式）
  CHECKSUM_FORMAT = %r{\A[A-Za-z0-9+/]{22}==\z}

  before_action :set_upload, except: :create

  rescue_from S3MultipartUpload::NotSupported, S3MultipartUpload::InvalidUpload do |error|
    render_error(error.message, :unprocessable_entity)
  end
  rescue_from ActionController::ParameterMissing, ArgumentError do |error|
    render_error("パラメータが不正です: #{error.message}", :bad_request)
  end
  rescue_from "Aws::S3::Errors::ServiceError" do |error|
    Rails.logger.error("[MultipartUpload] S3 エラー: #{error.class}: #{error.message}")
    render_error("ストレージとの通信に失敗しました", :bad_gateway)
  end

  # POST /multipart_uploads
  def create
    filename = params.require(:filename).to_s
    content_type = params.require(:content_type).to_s
    byte_size = Integer(params.require(:byte_size))

    return render_error("画像または動画のみアップロードできます", :unprocessable_entity) unless DirectUploadPolicy.allowed_content_type?(content_type)
    return render_error("ファイルサイズが不正です", :unprocessable_entity) unless byte_size.positive?

    upload = uploader.start(filename: filename, content_type: content_type)
    part_size = S3MultipartUpload.part_size_for(byte_size)
    token = verifier.generate(
      { "key" => upload[:key], "upload_id" => upload[:upload_id], "user_id" => current_user.id,
        "filename" => filename, "content_type" => content_type, "byte_size" => byte_size },
      purpose: TOKEN_PURPOSE, expires_in: TOKEN_EXPIRES_IN
    )

    render json: { token: token, part_size: part_size, part_count: part_count(byte_size) }
  end

  # POST /multipart_uploads/part_urls
  def part_urls
    part_numbers = Array(params.require(:part_numbers)).map { |number| Integer(number) }.uniq
    valid_range = 1..part_count(@upload["byte_size"])
    if part_numbers.size > MAX_PART_URLS_PER_REQUEST || !part_numbers.all? { |number| valid_range.cover?(number) }
      return render_error("パート番号が不正です", :unprocessable_entity)
    end

    render json: { urls: uploader.part_urls(key: @upload["key"], upload_id: @upload["upload_id"], part_numbers: part_numbers) }
  end

  # POST /multipart_uploads/complete
  def complete
    checksum = params.require(:checksum).to_s
    return render_error("チェックサムが不正です", :unprocessable_entity) unless checksum.match?(CHECKSUM_FORMAT)

    parts = params.permit(parts: [ :part_number, :etag ]).fetch(:parts).map do |part|
      { part_number: Integer(part[:part_number]), etag: part.require(:etag).to_s }
    end
    unless parts.map { |part| part[:part_number] }.sort == (1..part_count(@upload["byte_size"])).to_a
      return render_error("パートがそろっていません", :unprocessable_entity)
    end

    uploader.complete(key: @upload["key"], upload_id: @upload["upload_id"], parts: parts, byte_size: @upload["byte_size"])
    blob = ActiveStorage::Blob.create!(
      key: @upload["key"], filename: @upload["filename"], content_type: @upload["content_type"],
      byte_size: @upload["byte_size"], checksum: checksum, service_name: uploader.service_name
    )

    render json: { signed_id: blob.signed_id }
  end

  # POST /multipart_uploads/cancel
  def cancel
    uploader.abort(key: @upload["key"], upload_id: @upload["upload_id"])
    head :no_content
  end

  private

  def set_upload
    @upload = verifier.verified(params.require(:token).to_s, purpose: TOKEN_PURPOSE)
    return render_error("トークンが不正か期限切れです", :unprocessable_entity) if @upload.nil?

    render_error("このアップロードを操作する権限がありません", :forbidden) unless @upload["user_id"] == current_user.id
  end

  def uploader
    @uploader ||= S3MultipartUpload.new
  end

  def verifier
    Rails.application.message_verifier(TOKEN_PURPOSE)
  end

  def part_count(byte_size)
    (byte_size.to_f / S3MultipartUpload.part_size_for(byte_size)).ceil
  end

  def render_error(message, status)
    render json: { error: message }, status: status
  end
end
