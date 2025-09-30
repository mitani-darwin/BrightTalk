require "test_helper"

class UploadWorkflowsTest < ActionDispatch::IntegrationTest
  def setup
    @user = users(:test_user)
    @category = categories(:general)
    @post_type = post_types(:tutorial)
  end

  # === Complete Upload Workflows ===

  test "完全な画像アップロードワークフロー" do
    # ログイン
    sign_in @user

    # 新規投稿ページにアクセス
    get new_post_path
    assert_response :success
    assert_select "input[type='file'][name='post[images][]']"

    # 画像付きの投稿を作成
    image_file = fixture_file_upload('test_image.jpg', 'image/jpeg')
    
    assert_difference("Post.count", 1) do
      post posts_path, params: {
        post: {
          title: "画像アップロードテスト",
          content: "画像付き投稿のテスト",
          purpose: "テスト目的",
          target_audience: "テストユーザー",
          category_id: @category.id,
          post_type_id: @post_type.id,
          images: [image_file]
        }
      }
    end

    created_post = Post.last
    
    # 作成された投稿の確認
    assert created_post.images.attached?, "画像が添付されていません"
    assert_equal "画像アップロードテスト", created_post.title
    
    # 投稿詳細ページでの確認
    follow_redirect!
    assert_response :success
    assert_match "画像アップロードテスト", response.body
    
    # 編集ページでの画像表示確認
    get edit_post_path(created_post)
    assert_response :success
    assert_select "img" # 画像が表示されている
  end

  test "Direct Uploadを使った動画アップロードワークフロー" do
    sign_in @user

    # Direct Upload用のblobを事前作成
    video_blob = ActiveStorage::Blob.create_and_upload!(
      io: File.open(Rails.root.join("test", "fixtures", "files", "test_video.mp4")),
      filename: "integration_test_video.mp4",
      content_type: "video/mp4"
    )

    # 動画付きの投稿を作成（Direct Upload形式）
    assert_difference("Post.count", 1) do
      post posts_path, params: {
        post: {
          title: "動画アップロードテスト",
          content: "Direct Upload動画のテスト",
          purpose: "Direct Uploadテスト",
          target_audience: "開発者",
          category_id: @category.id,
          post_type_id: @post_type.id,
          video_signed_ids: [video_blob.signed_id]
        }
      }
    end

    created_post = Post.last
    assert created_post.videos.attached?, "動画が添付されていません"
    assert_equal "integration_test_video.mp4", created_post.videos.first.filename.to_s

    # 投稿詳細での動画確認
    follow_redirect!
    assert_response :success
    assert_match "動画アップロードテスト", response.body
  end

  test "自動保存ワークフローテスト" do
    sign_in @user

    # 自動保存（下書き作成）
    assert_difference("Post.count", 1) do
      post auto_save_posts_path, params: {
        title: "自動保存テスト投稿",
        content: "自動保存中の内容",
        purpose: "自動保存テスト",
        target_audience: "テストユーザー",
        category_id: @category.id,
        post_type_id: @post_type.id
      }, xhr: true
    end

    assert_response :success
    
    json_response = JSON.parse(response.body)
    assert json_response['success'], "自動保存が失敗しました"
    assert json_response['post_id'].present?, "post_idが返されていません"

    saved_post = Post.last
    assert_equal "draft", saved_post.status
    assert_equal "自動保存テスト投稿", saved_post.title

    # 下書きから公開への投稿完了
    patch post_path(saved_post), params: {
      post: {
        title: "更新された投稿タイトル",
        content: "更新された投稿内容",
        status: "published"
      }
    }

    saved_post.reload
    assert_equal "published", saved_post.status
    assert_equal "更新された投稿タイトル", saved_post.title
  end

  test "画像と動画を同時に含む複合アップロードワークフロー" do
    sign_in @user

    # 画像とDirect Upload動画の準備
    image_file = fixture_file_upload('test_image.jpg', 'image/jpeg')
    video_blob = ActiveStorage::Blob.create_and_upload!(
      io: File.open(Rails.root.join("test", "fixtures", "files", "test_video.mp4")),
      filename: "combo_test_video.mp4",
      content_type: "video/mp4"
    )

    assert_difference("Post.count", 1) do
      post posts_path, params: {
        post: {
          title: "マルチメディア投稿テスト",
          content: "画像と動画の両方を含む投稿",
          purpose: "複合アップロードテスト",
          target_audience: "マルチメディア対応テスト",
          category_id: @category.id,
          post_type_id: @post_type.id,
          images: [image_file],
          video_signed_ids: [video_blob.signed_id]
        }
      }
    end

    created_post = Post.last
    assert created_post.images.attached?, "画像が添付されていません"
    assert created_post.videos.attached?, "動画が添付されていません"
    assert_equal 1, created_post.images.count
    assert_equal 1, created_post.videos.count

    # 詳細ページでの表示確認
    follow_redirect!
    assert_response :success
    assert_match "マルチメディア投稿テスト", response.body
  end

  test "動画付き自動保存からの投稿完了ワークフロー" do
    sign_in @user

    # Direct Upload用動画準備
    video_blob = ActiveStorage::Blob.create_and_upload!(
      io: File.open(Rails.root.join("test", "fixtures", "files", "test_video.mp4")),
      filename: "auto_save_video.mp4",
      content_type: "video/mp4"
    )

    # 動画付き自動保存
    assert_difference("Post.count", 1) do
      post auto_save_posts_path, params: {
        title: "動画付き自動保存テスト",
        content: "動画を含む自動保存",
        video_signed_ids: [video_blob.signed_id]
      }, xhr: true
    end

    assert_response :success
    json_response = JSON.parse(response.body)
    assert json_response['success'], "動画付き自動保存が失敗しました"

    saved_post = Post.last
    assert_equal "draft", saved_post.status
    assert saved_post.videos.attached?, "動画が自動保存されていません"

    # 下書きを公開投稿に更新
    patch post_path(saved_post), params: {
      post: {
        title: saved_post.title,
        content: saved_post.content,
        purpose: "完成版動画投稿",
        target_audience: "動画視聴者",
        category_id: @category.id,
        post_type_id: @post_type.id,
        status: "published"
      }
    }

    saved_post.reload
    assert_equal "published", saved_post.status
    assert saved_post.videos.attached?, "公開時に動画が保持されていません"
  end

  test "投稿更新時の画像追加ワークフロー" do
    sign_in @user

    # 既存投稿を作成
    existing_post = Post.create!(
      title: "更新テスト投稿",
      content: "更新前の内容",
      purpose: "更新テスト",
      target_audience: "テストユーザー",
      user: @user,
      category: @category,
      post_type: @post_type,
      status: :published
    )

    # 編集ページにアクセス
    get edit_post_path(existing_post)
    assert_response :success

    # 画像を追加して更新
    image_file = fixture_file_upload('test_image.jpg', 'image/jpeg')
    
    patch post_path(existing_post), params: {
      post: {
        title: "画像が追加された投稿",
        content: "画像を追加しました",
        images: [image_file]
      }
    }

    existing_post.reload
    assert existing_post.images.attached?, "画像が追加されていません"
    assert_equal "画像が追加された投稿", existing_post.title

    # 更新後はリダイレクトされる
    assert_response :redirect
    
    # リダイレクト先を追跡
    follow_redirect!
    assert_response :success
    assert_match "投稿が更新されました", flash[:notice]
  end

  test "画像削除ワークフロー" do
    sign_in @user

    # 画像付き投稿を作成
    post_with_image = Post.create!(
      title: "画像削除テスト投稿",
      content: "画像削除のテスト",
      purpose: "削除テスト",
      target_audience: "テストユーザー",
      user: @user,
      category: @category,
      post_type: @post_type,
      status: :published
    )

    # 画像を添付
    post_with_image.images.attach(
      io: File.open(Rails.root.join("test", "fixtures", "files", "test_image.jpg")),
      filename: "delete_test_image.jpg",
      content_type: "image/jpeg"
    )

    attachment_id = post_with_image.images.first.id

    # 編集ページで画像が表示されることを確認
    get edit_post_path(post_with_image)
    assert_response :success
    assert_select "img" # 画像が表示されている

    # 画像削除を実行
    delete delete_image_post_path(post_with_image), params: {
      attachment_id: attachment_id
    }, xhr: true

    assert_response :success
    json_response = JSON.parse(response.body)
    assert json_response['success'], "画像削除が失敗しました"
    assert_match "delete_test_image.jpg", json_response['message']

    post_with_image.reload
    assert_not post_with_image.images.attached?, "画像が削除されていません"
  end

  test "エラーハンドリングワークフロー（無効なsigned_id）" do
    sign_in @user

    # 無効なsigned_idで投稿作成を試行
    assert_difference("Post.count", 1) do
      post posts_path, params: {
        post: {
          title: "エラーハンドリングテスト",
          content: "無効なsigned_idでのテスト",
          purpose: "エラーテスト",
          target_audience: "テストユーザー",
          category_id: @category.id,
          post_type_id: @post_type.id,
          video_signed_ids: ["invalid_signed_id_12345"]
        }
      }
    end

    # 投稿自体は作成されるが、動画は添付されない
    created_post = Post.last
    assert_equal "エラーハンドリングテスト", created_post.title
    assert_not created_post.videos.attached?, "無効なsigned_idで動画が添付されてしまいました"

    # 詳細ページが正常に表示される
    follow_redirect!
    assert_response :success
    assert_match "エラーハンドリングテスト", response.body
  end

  test "日本語ファイル名を含む完全ワークフロー" do
    sign_in @user

    # 日本語ファイル名の動画blob作成
    japanese_video_blob = ActiveStorage::Blob.create_and_upload!(
      io: File.open(Rails.root.join("test", "fixtures", "files", "test_video.mp4")),
      filename: "とぐろ島の神髄テスト動画.mp4",
      content_type: "video/mp4"
    )

    assert_difference("Post.count", 1) do
      post posts_path, params: {
        post: {
          title: "日本語ファイル名テスト",
          content: "日本語ファイル名での動画アップロード統合テスト",
          purpose: "国際化テスト",
          target_audience: "日本語ユーザー",
          category_id: @category.id,
          post_type_id: @post_type.id,
          video_signed_ids: [japanese_video_blob.signed_id]
        }
      }
    end

    created_post = Post.last
    assert created_post.videos.attached?, "日本語ファイル名の動画が添付されていません"
    assert_equal "とぐろ島の神髄テスト動画.mp4", created_post.videos.first.filename.to_s

    follow_redirect!
    assert_response :success
    assert_match "日本語ファイル名テスト", response.body
  end
end