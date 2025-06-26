
require "test_helper"

class CommentsControllerTest < ActionDispatch::IntegrationTest
  def setup
    @user = users(:test_user)
    @another_user = users(:another_user)
    @post = posts(:first_post)
    @comment = Comment.create!(
      content: "テストコメント",
      user: @user,
      post: @post
    )
  end

  test "ログインユーザーがコメントを作成できること" do
    sign_in @user

    assert_difference("Comment.count", 1) do
      post post_comments_path(@post), params: {
        comment: {
          content: "新しいコメント"
        }
      }
    end

    assert_redirected_to @post
    follow_redirect!
    assert_match "新しいコメント", response.body
  end

  test "未ログインユーザーはコメントを作成できないこと" do
    assert_no_difference("Comment.count") do
      post post_comments_path(@post), params: {
        comment: {
          content: "未ログインコメント"
        }
      }
    end

    assert_redirected_to new_user_session_path
  end

  test "無効なデータでコメント作成が失敗すること" do
    sign_in @user

    assert_no_difference("Comment.count") do
      post post_comments_path(@post), params: {
        comment: {
          content: "" # 空のコンテンツ
        }
      }
    end

    # CommentsControllerではリダイレクトでエラーを処理しているため
    assert_redirected_to @post
    follow_redirect!
    assert_match "コメントの投稿に失敗しました", response.body
  end

  test "コメント作成者がコメントを削除できること" do
    sign_in @user

    assert_difference("Comment.count", -1) do
      delete post_comment_path(@post, @comment)
    end

    assert_redirected_to @post
  end

  test "他人のコメントは削除できないこと" do
    sign_in @user
    other_comment = Comment.create!(
      content: "他人のコメント",
      user: @another_user,
      post: @post
    )

    assert_no_difference("Comment.count") do
      delete post_comment_path(@post, other_comment)
    end

    assert_redirected_to @post
    follow_redirect!
    assert_match "コメントの削除権限がありません", response.body
  end

  test "未ログインユーザーはコメントを削除できないこと" do
    assert_no_difference("Comment.count") do
      delete post_comment_path(@post, @comment)
    end

    assert_redirected_to new_user_session_path
  end

  test "存在しないコメントの削除で404エラーになること" do
    sign_in @user

    delete post_comment_path(@post, 99999)
    assert_response :not_found
  end

  test "長すぎるコメントは作成できないこと" do
    sign_in @user

    long_content = "a" * 501 # 500文字制限を超える

    assert_no_difference("Comment.count") do
      post post_comments_path(@post), params: {
        comment: {
          content: long_content
        }
      }
    end

    # CommentsControllerではリダイレクトでエラーを処理
    assert_redirected_to @post
    follow_redirect!
    assert_match "コメントの投稿に失敗しました", response.body
  end

  test "HTMLタグがエスケープされること" do
    sign_in @user

    malicious_content = "<script>alert('XSS')</script>安全なコメント"

    post post_comments_path(@post), params: {
      comment: {
        content: malicious_content
      }
    }

    assert_redirected_to @post
    follow_redirect!
    # HTMLタグがエスケープされているかチェック
    assert_no_match "<script>", response.body
    assert_match "安全なコメント", response.body
  end

  test "存在しない投稿にコメントを作成しようとして404エラーになること" do
    sign_in @user

    # 存在しない投稿IDでコメント作成を試行
    post "/posts/99999/comments", params: {
      comment: {
        content: "存在しない投稿へのコメント"
      }
    }
    assert_response :not_found
  end

  test "存在しない投稿のコメントを削除しようとして404エラーになること" do
    sign_in @user

    # 存在しない投稿IDでコメント削除を試行
    delete "/posts/99999/comments/#{@comment.id}"
    assert_response :not_found
  end

  test "正常なコメント作成時にフラッシュメッセージが表示されること" do
    sign_in @user

    post post_comments_path(@post), params: {
      comment: {
        content: "正常なコメント"
      }
    }

    assert_redirected_to @post
    follow_redirect!
    assert_match "コメントが投稿されました", response.body
  end

  test "コメント削除時にフラッシュメッセージが表示されること" do
    sign_in @user

    delete post_comment_path(@post, @comment)

    assert_redirected_to @post
    follow_redirect!
    assert_match "コメントが削除されました", response.body
  end

  test "Deviseヘルパーでのログイン確認" do
    # Deviseのsign_inヘルパーが正しく動作することを確認
    sign_in @user

    # ログイン状態でコメント作成
    post post_comments_path(@post), params: {
      comment: {
        content: "Deviseヘルパーテスト"
      }
    }

    assert_redirected_to @post

    # コメントが正しく作成されたか確認
    comment = Comment.last
    assert_equal @user, comment.user
    assert_equal "Deviseヘルパーテスト", comment.content
  end

  test "fixtureデータの整合性確認" do
    # fixtureのユーザーとコメントの関連が正しいか確認
    assert_equal @user, @comment.user
    assert_equal @post, @comment.post
    assert @comment.persisted?

    # another_userが異なるユーザーであることを確認
    assert_not_equal @user, @another_user
  end

  test "コメント作成時にuser_idが正しく設定されること" do
    sign_in @user

    post post_comments_path(@post), params: {
      comment: {
        content: "ユーザーIDテスト"
      }
    }

    comment = Comment.last
    assert_equal @user.id, comment.user_id
    assert_equal @post.id, comment.post_id
  end

  test "コメント削除の権限チェックが正しく動作すること" do
    # 他のユーザーのコメントを作成
    other_comment = Comment.create!(
      content: "別ユーザーのコメント",
      user: @another_user,
      post: @post
    )

    sign_in @user

    # 自分のコメントは削除できる
    assert_difference("Comment.count", -1) do
      delete post_comment_path(@post, @comment)
    end

    # 他人のコメントは削除できない（権限チェック）
    assert_no_difference("Comment.count") do
      delete post_comment_path(@post, other_comment)
    end

    assert_redirected_to @post
  end

  test "存在する投稿の存在しないコメント削除で404エラーになること" do
    sign_in @user

    # 存在する投稿だが存在しないコメントIDで削除を試行
    delete post_comment_path(@post, 99999)
    assert_response :not_found
  end

  test "URLパラメータでの404エラーテスト" do
    sign_in @user

    # 直接URLで存在しないリソースにアクセス
    delete "/posts/#{@post.id}/comments/99999"
    assert_response :not_found

    # 存在しない投稿の存在しないコメント
    delete "/posts/99999/comments/99999"
    assert_response :not_found
  end
end
