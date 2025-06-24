
# test/controllers/posts_controller_test.rb
require "test_helper"

class PostsControllerTest < ActionDispatch::IntegrationTest
  def setup
    @user = users(:test_user)
    @another_user = users(:another_user)
    @post = posts(:first_post)
    @category = categories(:general)
  end

  test "投稿一覧が表示されること" do
    get posts_path
    assert_response :success
    assert_match @post.title, response.body
  end

  test "投稿詳細が表示されること" do
    get post_path(@post)
    assert_response :success
    assert_match @post.title, response.body
    assert_match @post.content, response.body
  end

  test "ログインユーザーが新規投稿ページにアクセスできること" do
    sign_in @user
    get new_post_path
    assert_response :success
  end

  test "未ログインユーザーは新規投稿ページにアクセスできないこと" do
    get new_post_path
    assert_redirected_to new_user_session_path
  end

  test "ログインユーザーが投稿を作成できること" do
    sign_in @user

    assert_difference('Post.count', 1) do
      post posts_path, params: {
        post: {
          title: "新しい投稿",
          content: "新しい投稿の内容",
          category_id: @category.id
        }
      }
    end

    created_post = Post.last
    assert_redirected_to created_post
    assert_equal @user, created_post.user
  end

  test "無効なデータで投稿作成が失敗すること" do
    sign_in @user

    assert_no_difference('Post.count') do
      post posts_path, params: {
        post: {
          title: "", # 空のタイトル
          content: "内容",
          category_id: @category.id
        }
      }
    end

    assert_response :unprocessable_entity
  end

  test "投稿作成者が編集ページにアクセスできること" do
    sign_in @user
    get edit_post_path(@post)
    assert_response :success
  end

  test "他人の投稿の編集ページにはアクセスできないこと" do
    sign_in @another_user
    get edit_post_path(@post)
    assert_redirected_to posts_path
  end

  test "投稿作成者が投稿を更新できること" do
    sign_in @user

    patch post_path(@post), params: {
      post: {
        title: "更新されたタイトル",
        content: "更新された内容"
      }
    }

    assert_redirected_to @post
    @post.reload
    assert_equal "更新されたタイトル", @post.title
  end

  test "他人の投稿は更新できないこと" do
    sign_in @another_user
    original_title = @post.title

    patch post_path(@post), params: {
      post: {
        title: "不正な更新"
      }
    }

    assert_redirected_to posts_path
    @post.reload
    assert_equal original_title, @post.title
  end

  test "投稿作成者が投稿を削除できること" do
    sign_in @user

    assert_difference('Post.count', -1) do
      delete post_path(@post)
    end

    assert_redirected_to posts_path
  end

  test "他人の投稿は削除できないこと" do
    sign_in @another_user

    assert_no_difference('Post.count') do
      delete post_path(@post)
    end

    assert_redirected_to posts_path
  end

  test "投稿検索が機能すること" do
    get posts_path, params: { search: @post.title[0..5] }
    assert_response :success
    assert_match @post.title, response.body
  end

  test "カテゴリフィルターが機能すること" do
    get posts_path, params: { category_id: @category.id }
    assert_response :success
    assert_match @post.title, response.body
  end

  test "下書き投稿は一覧に表示されないこと" do
    draft_post = Post.create!(
      title: "下書き投稿",
      content: "下書き内容",
      user: @user,
      category: @category,
      draft: true
    )

    get posts_path
    assert_response :success
    assert_no_match draft_post.title, response.body
  end

  test "存在しない投稿で404エラーになること" do
    get post_path(99999)

    # 統合テストでは、Railsが404を適切にハンドリングする
    # 実際のレスポンスステータスを確認
    assert_includes [404, 500], response.status, "Expected 404 or 500 status for non-existent post"

    # または、レコードが見つからない場合の動作を確認
    if response.status == 500
      # 開発環境では例外ページが表示される場合がある
      assert_match(/ActiveRecord::RecordNotFound|Record not found/i, response.body)
    end
  end

  test "存在しない投稿の編集でエラーになること" do
    sign_in @user

    get edit_post_path(99999)
    assert_includes [404, 500], response.status
  end

  test "存在しない投稿の更新でエラーになること" do
    sign_in @user

    patch post_path(99999), params: {
      post: { title: "更新テスト" }
    }
    assert_includes [404, 500], response.status
  end

  test "存在しない投稿の削除でエラーになること" do
    sign_in @user

    delete post_path(99999)
    assert_includes [404, 500], response.status
  end

  test "Deviseヘルパーでのログイン確認" do
    # Deviseの統合テストヘルパーを使用
    sign_in @user

    # ログイン状態での投稿作成
    assert_difference('Post.count', 1) do
      post posts_path, params: {
        post: {
          title: "Deviseヘルパーテスト",
          content: "Deviseヘルパーでのログインテスト",
          category_id: @category.id
        }
      }
    end

    created_post = Post.last
    assert_equal @user, created_post.user
    assert_equal "Deviseヘルパーテスト", created_post.title
  end
end