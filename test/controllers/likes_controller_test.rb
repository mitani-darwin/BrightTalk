
require "test_helper"

class LikesControllerTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  def setup
    @user = users(:test_user)
    @post = posts(:first_post)
    # 既存のいいねをクリア
    Like.destroy_all
  end

  test "ログイン時にいいねを作成できること" do
    sign_in @user
    assert_difference('Like.count') do
      post "/posts/#{@post.id}/likes", as: :json
    end
    assert_response :success

    response_json = JSON.parse(response.body)
    assert_equal "created", response_json["status"]
  end

  test "重複のいいねを作成しないこと" do
    sign_in @user
    # 最初のいいねを作成
    post "/posts/#{@post.id}/likes", as: :json
    assert_response :success

    # 重複のいいねを試行
    assert_no_difference('Like.count') do
      post "/posts/#{@post.id}/likes", as: :json
    end
    assert_response :success

    response_json = JSON.parse(response.body)
    assert_equal "already_liked", response_json["status"]
  end

  test "既にいいねしている場合にいいねを削除できること" do
    sign_in @user

    # いいねを事前に作成
    like = Like.create!(user: @user, post: @post)

    # 作成されたことを確認
    assert_equal 1, Like.count

    # 正しいURLでいいねを削除（like IDを含む）
    assert_difference('Like.count', -1) do
      delete "/posts/#{@post.id}/likes/#{like.id}", as: :json
    end
    assert_response :success

    response_json = JSON.parse(response.body)
    assert_equal "destroyed", response_json["status"]
  end

  test "存在しないいいねを削除しようとした場合にエラーを返すこと" do
    sign_in @user

    # いいねが存在しないことを確認
    assert_equal 0, Like.count

    # 存在しないlike IDでDELETEリクエスト
    delete "/posts/#{@post.id}/likes/99999", as: :json
    assert_response :not_found

    # JSONレスポンスでエラー状態を確認
    response_json = JSON.parse(response.body)
    assert_equal "error", response_json["status"]
    assert_equal "Like not found", response_json["message"]
  end

  test "存在しない投稿IDでいいねしようとした場合にエラーを返すこと" do
    sign_in @user

    # 存在しない投稿IDでリクエスト
    post "/posts/99999/likes", as: :json
    assert_response :not_found

    response_json = JSON.parse(response.body)
    assert_equal "error", response_json["status"]
    assert_equal "Post not found", response_json["message"]
  end

  test "ログインしていない場合にリダイレクトされること" do
    post "/posts/#{@post.id}/likes"
    assert_response :redirect
    assert_redirected_to new_user_session_path
  end
end