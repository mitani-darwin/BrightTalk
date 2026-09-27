# ブラウザから S3 へ直接アップロードできるファイルの条件
# （ActiveStorage::DirectUploadsController と MultipartUploadsController で共通）
module DirectUploadPolicy
  ALLOWED_CONTENT_TYPE_PREFIXES = %w[image/ video/].freeze

  def self.allowed_content_type?(content_type)
    ALLOWED_CONTENT_TYPE_PREFIXES.any? { |prefix| content_type.to_s.start_with?(prefix) }
  end
end
