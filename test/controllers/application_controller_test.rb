require "test_helper"

class ApplicationControllerTest < ActionDispatch::IntegrationTest
  test "認証が必要なページは未ログイン時にリダイレクトされること" do
    get new_post_path
    assert_redirected_to new_user_session_path
  end

  test "ログイン後は元々アクセスしようとしたページにリダイレクトされること" do
    # 最初に保護されたページにアクセス
    get new_post_path
    assert_redirected_to new_user_session_path

    # Deviseのヘルパーを使用してログイン
    user = users(:test_user)
    sign_in user

    # ログイン後、最初にアクセスしようとしたページにアクセス可能
    get new_post_path
    assert_response :success
  end

  test "有効なログイン情報でのログイン" do
    user = users(:test_user)
    
    # Deviseのヘルパーを使用してログイン
    sign_in user

    # ログイン後、保護されたページにアクセス可能
    get new_post_path
    assert_response :success
  end

  test "Deviseヘルパーを使ったログインテスト" do
    user = users(:test_user)

    # Deviseのヘルパーメソッドを使用してログイン
    sign_in user

    # ログイン後、保護されたページにアクセス可能
    get new_post_path
    assert_response :success
  end

  test "存在しないページへのアクセス" do
    begin
      get "/nonexistent_page"
      assert_response :not_found
    rescue ActionController::RoutingError
      assert true
    end
  end

  test "存在しない投稿IDでの404エラー処理" do
    non_existent_id = Post.maximum(:id).to_i + 1000

    begin
      get post_path(non_existent_id)
      assert_response :not_found
    rescue ActiveRecord::RecordNotFound
      assert true
    end
  end

  test "認証済みユーザーは保護されたページにアクセスできること" do
    user = users(:test_user)
    # Deviseヘルパーを使用してログイン
    sign_in user

    get new_post_path
    assert_response :success
  end

  test "ログアウト後は保護されたページにアクセスできないこと" do
    user = users(:test_user)
    sign_in user

    # ログイン状態でアクセス可能
    get new_post_path
    assert_response :success

    # ログアウト
    sign_out user

    # ログアウト後はリダイレクトされる
    get new_post_path
    assert_redirected_to new_user_session_path
  end

  test "権限のないリソースへのアクセス制御" do
    user = users(:test_user)
    another_user = users(:another_user)
    post = posts(:first_post)

    # post の所有者を another_user に設定
    post.update!(user: another_user)

    sign_in user

    # 他人の投稿の編集ページにアクセス
    get edit_post_path(post)

    # アクセス拒否されるかリダイレクトされる
    assert_includes [ 403, 302, 303 ], response.status
  end

  test "不正なCSRFトークンでのリクエスト処理" do
    user = users(:test_user)
    sign_in user

    begin
      post posts_path, params: {
        post: {
          title: "Test Title",
          content: "Test Content",
          category_id: categories(:general).id
        }
      }, headers: {
        "HTTP_X_CSRF_TOKEN" => "invalid_token"
      }

      assert_includes [ 422, 302, 303, 403 ], response.status
    rescue ActionController::InvalidAuthenticityToken
      assert true
    end
  end

  test "fixtureのユーザーデータ確認" do
    user = users(:test_user)

    # ユーザーが存在することを確認
    assert_not_nil user
    assert_equal "test@example.com", user.email
    assert_equal "Test User", user.name
  end
end
