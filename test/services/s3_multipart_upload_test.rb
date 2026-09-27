require "test_helper"

class S3MultipartUploadTest < ActiveSupport::TestCase
  include StubS3Service

  setup do
    @service = build_stub_s3_service
    @client = @service.bucket.client
    @upload = S3MultipartUpload.new(service: @service)
  end

  test "S3以外のストレージでは利用できないこと" do
    assert_raises(S3MultipartUpload::NotSupported) { S3MultipartUpload.new(service: ActiveStorage::Blob.service) }
  end

  test "パートサイズは16MB以上で、パート数が10,000を超えないこと" do
    assert_equal 16.megabytes, S3MultipartUpload.part_size_for(1.gigabyte)
    size = 1.terabyte
    part_size = S3MultipartUpload.part_size_for(size)
    assert_operator (size.to_f / part_size).ceil, :<=, 10_000
  end

  test "開始するとキーとアップロードIDを返し、形式とファイル名を指定すること" do
    @client.stub_responses(:create_multipart_upload, upload_id: "upload-1")

    result = @upload.start(filename: "動画.mp4", content_type: "video/mp4")

    assert_equal "upload-1", result[:upload_id]
    assert_match StorageAudit::BLOB_KEY_FORMAT, result[:key]
    request = @client.api_requests.last
    assert_equal "video/mp4", request[:params][:content_type]
    assert_match "inline", request[:params][:content_disposition]
  end

  test "パートごとの署名付きURLを返すこと" do
    urls = @upload.part_urls(key: "k" * 28, upload_id: "upload-1", part_numbers: [ 1, 2 ])

    assert_equal [ 1, 2 ], urls.keys
    assert_match "partNumber=2", urls[2]
    assert_match "uploadId=upload-1", urls[2]
    assert_match "X-Amz-Signature", urls[2]
  end

  test "完了時にパート番号順に結合し、サイズを確認すること" do
    @client.stub_responses(:head_object, content_length: 100)

    @upload.complete(key: "k" * 28, upload_id: "upload-1", byte_size: 100,
                     parts: [ { part_number: 2, etag: "b" }, { part_number: 1, etag: "a" } ])

    complete = @client.api_requests.find { |r| r[:operation_name] == :complete_multipart_upload }
    assert_equal [ 1, 2 ], complete[:params][:multipart_upload][:parts].map { |p| p[:part_number] }
  end

  test "サイズが宣言と違う場合はファイルを削除してエラーにすること" do
    @client.stub_responses(:head_object, content_length: 99)

    assert_raises(S3MultipartUpload::InvalidUpload) do
      @upload.complete(key: "k" * 28, upload_id: "upload-1", byte_size: 100, parts: [ { part_number: 1, etag: "a" } ])
    end
    assert @client.api_requests.any? { |r| r[:operation_name] == :delete_object }
  end

  test "中止済みのアップロードを中止してもエラーにしないこと" do
    @client.stub_responses(:abort_multipart_upload, "NoSuchUpload")

    assert_nothing_raised { @upload.abort(key: "k" * 28, upload_id: "upload-1") }
  end
end
