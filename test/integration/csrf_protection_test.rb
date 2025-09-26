require "test_helper"

class CsrfProtectionTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  def setup
    @user = User.create!(
      name: "Test User",
      email: "test@example.com",
      password: "Password123!",
      confirmed_at: Time.current
    )
    @post = Post.create!(
      title: "Test Post",
      content: "Test content",
      user: @user,
      status: "draft"
    )
  end

  test "should allow POST request with valid CSRF token" do
    sign_in @user
    get edit_post_path(@post)
    assert_response :success

    # Extract CSRF token from the response
    csrf_token = css_select('meta[name="csrf-token"]').first['content']
    assert_not_nil csrf_token

    # Make POST request with CSRF token
    patch post_path(@post), params: {
      post: {
        title: "Updated Title",
        content: "Updated content"
      },
      authenticity_token: csrf_token
    }

    assert_redirected_to drafts_posts_path
    follow_redirect!
    assert_select '.alert-success', text: /投稿が更新されました/
  end

  test "should reject POST request without CSRF token" do
    sign_in @user
    
    # Attempt to make request without CSRF token
    assert_raises ActionController::InvalidAuthenticityToken do
      patch post_path(@post), params: {
        post: {
          title: "Updated Title",
          content: "Updated content"
        }
      }
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
    csrf_token = css_select('meta[name="csrf-token"]').first['content']

    # Test multipart form submission
    patch post_path(@post), params: {
      post: {
        title: "Updated with file",
        content: "Content with file",
        images: [fixture_file_upload("test_image.jpg", "image/jpeg")]
      },
      authenticity_token: csrf_token
    }

    assert_redirected_to drafts_posts_path
  end

  test "should maintain CSRF protection for API requests" do
    sign_in @user
    
    # JSON API request should still require CSRF token
    assert_raises ActionController::InvalidAuthenticityToken do
      post posts_path, params: {
        post: {
          title: "API Created",
          content: "API content"
        }
      }, as: :json
    end
  end

  test "should allow CSRF token in request header" do
    sign_in @user
    get edit_post_path(@post)
    csrf_token = css_select('meta[name="csrf-token"]').first['content']

    # Make request with CSRF token in header
    patch post_path(@post), params: {
      post: {
        title: "Header Token Test",
        content: "Content with header token"
      }
    }, headers: {
      'X-CSRF-Token' => csrf_token
    }

    assert_redirected_to drafts_posts_path
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