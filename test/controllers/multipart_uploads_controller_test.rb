require "test_helper"

class MultipartUploadsControllerTest < ActionDispatch::IntegrationTest
  include StubS3Service

  CHECKSUM = Digest::MD5.base64digest("video")

  setup do
    @service = build_stub_s3_service
    @client = @service.bucket.client
    @client.stub_responses(:create_multipart_upload, upload_id: "upload-1")
    S3MultipartUpload.service_override = @service
  end

  teardown do
    S3MultipartUpload.service_override = nil
  end

  def start_upload(content_type: "video/mp4", byte_size: 40.megabytes)
    post multipart_uploads_path, params: { filename: "movie.mp4", content_type: content_type, byte_size: byte_size }, as: :json
    response.parsed_body
  end

  def complete_upload(token, parts:, checksum: CHECKSUM)
    post complete_multipart_uploads_path, params: { token: token, checksum: checksum, parts: parts }, as: :json
  end

  test "未ログインでは開始できないこと" do
    start_upload

    assert_response :unauthorized
  end

  test "開始するとトークンとパートの分け方を返すこと" do
    sign_in users(:test_user)

    body = start_upload(byte_size: 40.megabytes)

    assert_response :success
    assert body["token"].present?
    assert_equal 16.megabytes, body["part_size"]
    assert_equal 3, body["part_count"]
  end

  test "画像・動画以外の形式は開始できないこと" do
    sign_in users(:test_user)

    start_upload(content_type: "text/html")

    assert_response :unprocessable_entity
  end

  test "S3以外のストレージでは開始できないこと" do
    S3MultipartUpload.service_override = nil # テスト環境は Disk
    sign_in users(:test_user)

    start_upload

    assert_response :unprocessable_entity
  end

  test "範囲内のパート番号の署名付きURLを返し、範囲外は拒否すること" do
    sign_in users(:test_user)
    token = start_upload(byte_size: 40.megabytes)["token"]

    post part_urls_multipart_uploads_path, params: { token: token, part_numbers: [ 1, 3 ] }, as: :json
    assert_response :success
    assert_equal %w[1 3], response.parsed_body["urls"].keys

    post part_urls_multipart_uploads_path, params: { token: token, part_numbers: [ 4 ] }, as: :json
    assert_response :unprocessable_entity
  end

  test "完了するとblobを作りsigned_idを返すこと" do
    sign_in users(:test_user)
    token = start_upload(byte_size: 40.megabytes)["token"]
    @client.stub_responses(:head_object, content_length: 40.megabytes)

    assert_difference("ActiveStorage::Blob.count", 1) do
      complete_upload(token, parts: [ 1, 2, 3 ].map { |n| { part_number: n, etag: "etag-#{n}" } })
    end

    assert_response :success
    blob = ActiveStorage::Blob.find_signed!(response.parsed_body["signed_id"])
    assert_equal "movie.mp4", blob.filename.to_s
    assert_equal "video/mp4", blob.content_type
    assert_equal 40.megabytes, blob.byte_size
    assert_equal CHECKSUM, blob.checksum
  end

  test "パートがそろっていない場合は完了できないこと" do
    sign_in users(:test_user)
    token = start_upload(byte_size: 40.megabytes)["token"]

    assert_no_difference("ActiveStorage::Blob.count") do
      complete_upload(token, parts: [ { part_number: 1, etag: "a" }, { part_number: 2, etag: "b" } ])
    end
    assert_response :unprocessable_entity
  end

  test "チェックサムの形式が不正な場合は完了できないこと" do
    sign_in users(:test_user)
    token = start_upload(byte_size: 10.megabytes)["token"]

    complete_upload(token, parts: [ { part_number: 1, etag: "a" } ], checksum: "invalid")

    assert_response :unprocessable_entity
  end

  test "サイズが宣言と違う場合はblobを作らないこと" do
    sign_in users(:test_user)
    token = start_upload(byte_size: 10.megabytes)["token"]
    @client.stub_responses(:head_object, content_length: 1)

    assert_no_difference("ActiveStorage::Blob.count") do
      complete_upload(token, parts: [ { part_number: 1, etag: "a" } ])
    end
    assert_response :unprocessable_entity
  end

  test "他のユーザーのアップロードは操作できないこと" do
    sign_in users(:test_user)
    token = start_upload["token"]
    sign_out :user
    sign_in users(:another_user)

    post cancel_multipart_uploads_path, params: { token: token }, as: :json

    assert_response :forbidden
  end

  test "改ざんしたトークンは拒否すること" do
    sign_in users(:test_user)

    post cancel_multipart_uploads_path, params: { token: "invalid" }, as: :json

    assert_response :unprocessable_entity
  end

  test "中止するとS3の分割アップロードを中止すること" do
    sign_in users(:test_user)
    token = start_upload["token"]

    post cancel_multipart_uploads_path, params: { token: token }, as: :json

    assert_response :no_content
    assert @client.api_requests.any? { |r| r[:operation_name] == :abort_multipart_upload }
  end
end
