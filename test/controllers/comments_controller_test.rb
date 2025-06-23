# test/controllers/comments_controller_test.rb
require "test_helper"

class CommentsControllerTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  def setup
    @user = users(:test_user)
    @post = posts(:first_post)
  end

  test "should create comment when signed in" do
    sign_in @user
    assert_difference('Comment.count') do
      post post_comments_url(@post), params: {
        comment: { content: "Test comment" }
      }
    end
    assert_redirected_to @post
  end

  test "should redirect when not signed in" do
    post post_comments_url(@post), params: {
      comment: { content: "Test comment" }
    }
    assert_response :redirect
  end
end