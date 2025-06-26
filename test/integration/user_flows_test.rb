
require "test_helper"

class UserFlowsTest < ActionDispatch::IntegrationTest
  test "user login and post creation flow" do
    # 既存のユーザーでログイン（確認済み）
    user = users(:test_user)

    # ログイン
    post user_session_path, params: {
      user: {
        email: user.email,
        password: "Secure#P@ssw0rd9"
      }
    }
    assert_response :redirect
    follow_redirect!

    # 投稿作成ページにアクセス
    get new_post_path
    assert_response :success

    # 投稿作成
    assert_difference("Post.count") do
      post posts_path, params: {
        post: {
          title: "Integration Test Post",
          content: "This is an integration test post",
          category_id: categories(:general).id
        }
      }
    end
    assert_response :redirect
  end

  test "should show login form" do
    get new_user_session_path
    assert_response :success
    assert_select "form"
  end

  test "should redirect when not authenticated" do
    get new_post_path
    assert_response :redirect
    assert_redirected_to new_user_session_path
  end
end
