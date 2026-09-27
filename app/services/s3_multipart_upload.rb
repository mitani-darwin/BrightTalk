require "aws-sdk-s3"

# S3 の分割アップロード（multipart upload）
# ブラウザが各パートを署名付き URL へ直接 PUT し、サーバーは開始・URL 発行・完了・中止だけを行う
# 1回の PUT で送れない 5GB 超の動画にも対応するため、大きな動画のアップロードに使う
class S3MultipartUpload
  class NotSupported < StandardError; end
  class InvalidUpload < StandardError; end

  # パートは最小 5MB（最後を除く）、最大 10,000 個という S3 の制約に収まるように決める
  MIN_PART_SIZE = 16.megabytes
  MAX_PARTS = 10_000
  PART_URL_EXPIRES_IN = 1.hour

  class << self
    # テスト用: ActiveStorage::Blob.service の代わりに使うサービス
    attr_accessor :service_override

    def part_size_for(byte_size)
      [ MIN_PART_SIZE, (byte_size.to_f / MAX_PARTS).ceil ].max
    end
  end

  def initialize(service: self.class.service_override || ActiveStorage::Blob.service)
    raise NotSupported, "分割アップロードは S3 のストレージでのみ利用できます" unless service.respond_to?(:bucket)

    @service = service
    @bucket = service.bucket
    @client = service.bucket.client
  end

  # 分割アップロードを開始し、保存先のキーとアップロード ID を返す
  def start(filename:, content_type:)
    key = ActiveStorage::Blob.generate_unique_secure_token
    response = @client.create_multipart_upload(
      bucket: @bucket.name,
      key: key,
      content_type: content_type,
      content_disposition: ActionDispatch::Http::ContentDisposition.format(disposition: "inline", filename: filename),
      **@service.upload_options
    )
    { key: key, upload_id: response.upload_id }
  end

  # 指定したパート番号の署名付きアップロード URL を返す（{ パート番号 => URL }）
  def part_urls(key:, upload_id:, part_numbers:)
    presigner = Aws::S3::Presigner.new(client: @client)
    part_numbers.index_with do |part_number|
      presigner.presigned_url(:upload_part, bucket: @bucket.name, key: key, upload_id: upload_id,
                                            part_number: part_number, expires_in: PART_URL_EXPIRES_IN.to_i)
    end
  end

  # パートを結合して1つのファイルにし、宣言どおりのサイズか確認する
  # parts: [{ part_number:, etag: }]
  def complete(key:, upload_id:, parts:, byte_size:)
    @client.complete_multipart_upload(
      bucket: @bucket.name,
      key: key,
      upload_id: upload_id,
      multipart_upload: { parts: parts.sort_by { |part| part[:part_number] } }
    )

    actual_size = @client.head_object(bucket: @bucket.name, key: key).content_length
    return if actual_size == byte_size

    @client.delete_object(bucket: @bucket.name, key: key)
    raise InvalidUpload, "アップロードされたサイズ（#{actual_size}）が宣言（#{byte_size}）と一致しません"
  end

  def abort(key:, upload_id:)
    @client.abort_multipart_upload(bucket: @bucket.name, key: key, upload_id: upload_id)
  rescue Aws::S3::Errors::NoSuchUpload
    # すでに完了・中止済み
  end

  def service_name
    @service.name
  end
end
