require "test_helper"

class DirectUploadAuthTest < ActionDispatch::IntegrationTest
  def direct_upload(content_type: "video/mp4", byte_size: 1.megabyte)
    post rails_direct_uploads_path, params: {
      blob: { filename: "test.mp4", content_type: content_type, byte_size: byte_size, checksum: Digest::MD5.base64digest("x") }
    }, as: :json
  end

  test "未ログインでは直接アップロードできないこと" do
    assert_no_difference("ActiveStorage::Blob.count") { direct_upload }

    assert_response :unauthorized
  end

  test "ログイン中は動画を直接アップロードできること" do
    sign_in users(:test_user)

    assert_difference("ActiveStorage::Blob.count", 1) { direct_upload }

    assert_response :success
    assert response.parsed_body.dig("direct_upload", "url").present?
  end

  test "画像・動画以外の形式は直接アップロードできないこと" do
    sign_in users(:test_user)

    assert_no_difference("ActiveStorage::Blob.count") { direct_upload(content_type: "text/html") }

    assert_response :unprocessable_entity
  end

  test "上限を超えるサイズは直接アップロードできないこと" do
    sign_in users(:test_user)

    assert_no_difference("ActiveStorage::Blob.count") { direct_upload(byte_size: 2.gigabytes + 1) }

    assert_response :unprocessable_entity
  end

  test "CSRFトークンが無い場合は直接アップロードできないこと" do
    sign_in users(:test_user)
    original = ActionController::Base.allow_forgery_protection
    ActionController::Base.allow_forgery_protection = true

    assert_no_difference("ActiveStorage::Blob.count") { direct_upload }

    assert_response :unprocessable_entity
  ensure
    ActionController::Base.allow_forgery_protection = original
  end
end
