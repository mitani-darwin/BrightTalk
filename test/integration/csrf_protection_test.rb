require "test_helper"

class CsrfProtectionTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  def setup
    # Skip these tests if CSRF protection is disabled in test environment
    skip "CSRF protection is disabled in test environment" unless ActionController::Base.allow_forgery_protection
    @user = User.create!(
      name: "CSRF Test User",
      email: "csrf_test@example.com",
      confirmed_at: Time.current
    )
    @category = categories(:general)
    @post_type = post_types(:tutorial)
    @post = Post.create!(
      title: "Test Post",
      content: "Test content",
      purpose: "Test purpose",
      target_audience: "Test audience",
      user: @user,
      category: @category,
      post_type: @post_type,
      status: "draft"
    )
  end

  test "should allow POST request with valid CSRF token" do
    sign_in @user
    get edit_post_path(@post)
    assert_response :success

    # Extract CSRF token from the response
    csrf_meta_tag = css_select('meta[name="csrf-token"]').first
    assert_not_nil csrf_meta_tag, "CSRF meta tag should be present"
    csrf_token = csrf_meta_tag['content']
    assert_not_nil csrf_token, "CSRF token should not be nil"

    # Make POST request with CSRF token
    patch post_path(@post), params: {
      post: {
        title: "Updated Title",
        content: "Updated content"
      },
      authenticity_token: csrf_token
    }

    assert_redirected_to @post
    follow_redirect!
    assert_select '.alert', text: /投稿が更新されました/
  end

  test "should reject POST request without CSRF token" do
    sign_in @user
    
    # Attempt to make request without CSRF token
    begin
      patch post_path(@post), params: {
        post: {
          title: "Updated Title",
          content: "Updated content"
        }
      }
      # If no exception raised, check for error status
      assert_includes [422, 403], response.status, "Should return error status without CSRF token"
    rescue ActionController::InvalidAuthenticityToken
      # Exception is also acceptable
      assert true
    end
  end

  test "should allow ActiveStorage uploads without CSRF token" do
    # Test that ActiveStorage endpoints are exempt from CSRF protection
    get "/rails/active_storage/blobs/redirect/#{SecureRandom.uuid}/test.jpg"
    # Should not raise CSRF error (might return 404, but not CSRF error)
    assert_response :not_found
  end

  test "should handle form submission with file uploads" do
    sign_in @user
    get edit_post_path(@post)
    assert_response :success
    
    csrf_meta_tag = css_select('meta[name="csrf-token"]').first
    assert_not_nil csrf_meta_tag, "CSRF meta tag should be present"
    csrf_token = csrf_meta_tag['content']
    assert_not_nil csrf_token, "CSRF token should not be nil"

    # Test multipart form submission
    patch post_path(@post), params: {
      post: {
        title: "Updated with file",
        content: "Content with file",
        images: [fixture_file_upload("test_image.jpg", "image/jpeg")]
      },
      authenticity_token: csrf_token
    }

    assert_redirected_to @post
  end

  test "should maintain CSRF protection for API requests" do
    sign_in @user
    
    # JSON API request should still require CSRF token
    begin
      post posts_path, params: {
        post: {
          title: "API Created",
          content: "API content"
        }
      }, as: :json
      # If no exception raised, check for error status
      assert_includes [422, 403], response.status, "Should return error status for JSON requests without CSRF token"
    rescue ActionController::InvalidAuthenticityToken
      # Exception is also acceptable
      assert true
    end
  end

  test "should allow CSRF token in request header" do
    sign_in @user
    get edit_post_path(@post)
    assert_response :success
    
    csrf_meta_tag = css_select('meta[name="csrf-token"]').first
    assert_not_nil csrf_meta_tag, "CSRF meta tag should be present"
    csrf_token = csrf_meta_tag['content']
    assert_not_nil csrf_token, "CSRF token should not be nil"

    # Make request with CSRF token in header
    patch post_path(@post), params: {
      post: {
        title: "Header Token Test",
        content: "Content with header token"
      }
    }, headers: {
      'X-CSRF-Token' => csrf_token
    }

    assert_redirected_to @post
  end

  private

  def fixture_file_upload(file, content_type)
    # Create a temporary file for testing
    file_path = Rails.root.join('test', 'fixtures', 'files', file)
    FileUtils.mkdir_p(File.dirname(file_path))
    File.write(file_path, "test image content") unless File.exist?(file_path)
    
    Rack::Test::UploadedFile.new(file_path, content_type)
  end
end