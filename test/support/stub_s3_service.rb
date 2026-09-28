require "active_storage/service/s3_service"

# AWS SDK のスタブ応答を使う S3 サービス（本物の S3 には接続しない）
module StubS3Service
  def build_stub_s3_service
    ActiveStorage::Service::S3Service.new(
      bucket: "test-bucket", region: "ap-northeast-1",
      access_key_id: "test", secret_access_key: "test", stub_responses: true
    ).tap { |service| service.name = "test" }
  end
end
