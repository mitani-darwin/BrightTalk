require "test_helper"

class PostsControllerTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  def setup
    @user = users(:test_user)
    @category = categories(:general)
    @post = posts(:first_post)
  end

  test "投稿一覧を取得できること" do
    get posts_url
    assert_response :success
  end

  test "投稿詳細を表示できること" do
    get post_url(@post)
    assert_response :success
  end

  test "ログイン時に新規投稿画面を取得できること" do
    sign_in @user
    get new_post_url
    assert_response :success
  end

  test "未認証時にログイン画面にリダイレクトされること" do
    get new_post_url
    assert_response :redirect
  end
end