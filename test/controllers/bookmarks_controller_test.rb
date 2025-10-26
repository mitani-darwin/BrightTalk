# test/controllers/bookmarks_controller_test.rb
require "test_helper"

class BookmarksControllerTest < ActionDispatch::IntegrationTest
  def setup
    @user = users(:test_user)
    @another_user = users(:another_user)
    @post = posts(:first_post)

    Bookmark.where(user: [ @user, @another_user ]).destroy_all
  end

  test "ログインしていない場合はブックマーク一覧にアクセスできないこと" do
    get bookmarks_path
    assert_response :redirect
    assert_redirected_to new_user_session_path
  end

  test "ログインユーザーがブックマーク一覧を表示できること" do
    Bookmark.create!(user: @user, post: @post)
    sign_in @user

    get bookmarks_path
    assert_response :success
    assert_select "h1", text: "ブックマーク一覧"
    assert_select "a", text: @post.title
  end

  test "ログインユーザーが投稿をブックマークできること" do
    sign_in @user

    assert_difference("Bookmark.count", 1) do
      post post_bookmarks_path(@post),
           xhr: true,
           headers: { "Accept" => "application/json" }
    end

    assert_response :success
    assert Bookmark.exists?(user: @user, post: @post)
    json = JSON.parse(response.body)
    assert_equal "created", json["status"]
  end

  test "未ログインユーザーはブックマークできないこと" do
    assert_no_difference("Bookmark.count") do
      post post_bookmarks_path(@post),
           xhr: true,
           headers: { "Accept" => "application/json" }
    end

    assert_response :unauthorized
  end

  test "同じ投稿を重複してブックマークできないこと" do
    sign_in @user
    Bookmark.create!(user: @user, post: @post)

    assert_no_difference("Bookmark.count") do
      post post_bookmarks_path(@post),
           xhr: true,
           headers: { "Accept" => "application/json" }
    end

    assert_response :success
    json = JSON.parse(response.body)
    assert_equal "already_bookmarked", json["status"]
  end

  test "ログインユーザーがブックマークを解除できること" do
    sign_in @user
    bookmark = Bookmark.create!(user: @user, post: @post)

    assert_difference("Bookmark.count", -1) do
      delete post_bookmark_path(@post, bookmark),
             xhr: true,
             headers: { "Accept" => "application/json" }
    end

    assert_response :success
    json = JSON.parse(response.body)
    assert_equal "destroyed", json["status"]
  end

  test "他人のブックマークは削除できないこと" do
    bookmark = Bookmark.create!(user: @user, post: @post)
    sign_in @another_user

    assert_no_difference("Bookmark.count") do
      delete post_bookmark_path(@post, bookmark),
             xhr: true,
             headers: { "Accept" => "application/json" }
    end

    assert_response :unauthorized
  end

  test "存在しない投稿にブックマークしようとすると404を返すこと" do
    sign_in @user

    assert_no_difference("Bookmark.count") do
      post "/posts/999999/bookmarks",
           xhr: true,
           headers: { "Accept" => "application/json" }
    end

    assert_response :not_found
  end

  test "存在しないブックマークを削除しようとすると404を返すこと" do
    sign_in @user

    delete "/posts/#{@post.to_param}/bookmarks/999999",
           xhr: true,
           headers: { "Accept" => "application/json" }

    assert_response :not_found
  end

  test "JSONレスポンスにブックマーク数が含まれること" do
    sign_in @user

    post post_bookmarks_path(@post),
         xhr: true,
         headers: { "Accept" => "application/json" }

    json = JSON.parse(response.body)
    assert json.key?("bookmarks_count")
  end
end
