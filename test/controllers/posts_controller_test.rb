require "test_helper"

class PostsControllerTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  def setup
    @user = users(:test_user)
    @category = categories(:general)
    @post = posts(:first_post)
  end

  test "should get index" do
    get posts_url
    assert_response :success
  end

  test "should show post" do
    get post_url(@post)
    assert_response :success
  end

  test "should get new when signed in" do
    sign_in @user
    get new_post_url
    assert_response :success
  end

  test "should redirect to sign in when not authenticated" do
    get new_post_url
    assert_response :redirect
  end
end