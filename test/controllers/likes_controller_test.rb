# test/controllers/likes_controller_test.rb
require "test_helper"

class LikesControllerTest < ActionDispatch::IntegrationTest
  def setup
    @user = users(:test_user)
    @another_user = users(:another_user)
    @post = posts(:first_post)

    # 既存のいいねをクリア
    Like.where(user: [ @user, @another_user ], post: @post).destroy_all
  end

  test "ログインユーザーが投稿にいいねできること" do
    sign_in @user

    assert_difference("Like.count", 1) do
      post post_likes_path(@post), xhr: true, headers: { "Accept" => "application/json" }
    end

    assert_response :success
    assert Like.exists?(user: @user, post: @post)
  end

  test "未ログインユーザーはいいねできないこと" do
    assert_no_difference("Like.count") do
      post post_likes_path(@post), xhr: true, headers: { "Accept" => "application/json" }
    end

    assert_response :unauthorized
  end

  test "同じ投稿に重複していいねできないこと" do
    sign_in @user

    # 最初のいいね
    Like.create!(user: @user, post: @post)

    assert_no_difference("Like.count") do
      post post_likes_path(@post), xhr: true, headers: { "Accept" => "application/json" }
    end

    # コントローラーはJSONレスポンスを返すが、ステータスは200
    assert_response :success

    # レスポンスボディをチェック
    json_response = JSON.parse(response.body)
    assert_equal "already_liked", json_response["status"]
  end

  test "ログインユーザーがいいねを取り消しできること" do
    sign_in @user
    like = Like.create!(user: @user, post: @post)

    assert_difference("Like.count", -1) do
      delete post_like_path(@post, like), xhr: true, headers: { "Accept" => "application/json" }
    end

    assert_response :success
    assert_not Like.exists?(user: @user, post: @post)
  end

  test "他人のいいねは削除できないこと" do
    sign_in @another_user
    like = Like.create!(user: @user, post: @post)

    assert_no_difference("Like.count") do
      delete post_like_path(@post, like), xhr: true, headers: { "Accept" => "application/json" }
    end

    assert_response :unauthorized
  end

  test "存在しない投稿にいいねしようとすると404エラーになること" do
    sign_in @user

    assert_no_difference("Like.count") do
      post "/posts/99999/likes", xhr: true, headers: { "Accept" => "application/json" }
    end

    assert_response :not_found
  end

  test "存在しないいいねを削除しようとすると404エラーになること" do
    sign_in @user

    delete "/posts/#{@post.id}/likes/99999", xhr: true, headers: { "Accept" => "application/json" }
    assert_response :not_found
  end

  test "いいね数が正しく更新されること" do
    sign_in @user
    initial_count = @post.likes.count

    post post_likes_path(@post), xhr: true, headers: { "Accept" => "application/json" }
    @post.reload

    assert_equal initial_count + 1, @post.likes.count
  end

  test "いいね取り消し時にいいね数が正しく更新されること" do
    sign_in @user
    like = Like.create!(user: @user, post: @post)
    @post.reload  # リロードして正確な初期カウントを取得
    initial_count = @post.likes.count

    assert_difference("Like.count", -1) do
      delete post_like_path(@post, like), xhr: true, headers: { "Accept" => "application/json" }
    end

    assert_response :success
    @post.reload

    assert_equal initial_count - 1, @post.likes.count
  end

  test "複数のユーザーが同じ投稿にいいねできること" do
    # 最初のユーザーがいいね
    sign_in @user
    post post_likes_path(@post), xhr: true, headers: { "Accept" => "application/json" }
    assert_response :success

    # ログアウト
    sign_out @user

    # 別のユーザーがいいね
    sign_in @another_user
    assert_difference("Like.count", 1) do
      post post_likes_path(@post), xhr: true, headers: { "Accept" => "application/json" }
    end
    assert_response :success

    @post.reload
    assert_equal 2, @post.likes.count
  end

  test "AJAX以外のリクエストでも成功レスポンスが返ること" do
    sign_in @user

    post post_likes_path(@post)
    assert_response :success
  end

  test "存在しない投稿の存在しないいいねを削除しようとすると404エラーになること" do
    sign_in @user

    delete "/posts/99999/likes/99999", xhr: true, headers: { "Accept" => "application/json" }
    assert_response :not_found
  end

  test "JSONレスポンスのフォーマットが正しいこと" do
    sign_in @user

    post post_likes_path(@post), xhr: true, headers: { "Accept" => "application/json" }
    assert_response :success

    json_response = JSON.parse(response.body)
    assert_equal "created", json_response["status"]
    assert json_response.has_key?("likes_count")
  end

  test "いいね削除時のJSONレスポンスが正しいこと" do
    sign_in @user
    like = Like.create!(user: @user, post: @post)

    delete post_like_path(@post, like), xhr: true, headers: { "Accept" => "application/json" }
    assert_response :success

    json_response = JSON.parse(response.body)
    assert_equal "destroyed", json_response["status"]
    assert json_response.has_key?("likes_count")
  end
end
