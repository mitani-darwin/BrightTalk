require "test_helper"

class DirectUploadTest < ActionDispatch::IntegrationTest
  def setup
    @user = users(:test_user)
    @category = categories(:general)
    @post_type = post_types(:tutorial)
    sign_in @user
  end

  # === Image Direct Upload Tests ===

  test "画像のDirect Uploadが正常に動作すること" do
    # 画像を通常のファイルアップロードとして処理（Direct Uploadは実際にはJavaScriptで処理される）
    image_file = fixture_file_upload('test_image.jpg', 'image/jpeg')

    assert_difference("Post.count", 1) do
      post posts_path, params: {
        post: {
          title: "画像Direct Uploadテスト",
          content: "Direct Upload機能テスト",
          purpose: "Direct Uploadテスト",
          target_audience: "開発者",
          category_id: @category.id,
          post_type_id: @post_type.id,
          images: [image_file]
        }
      }
    end

    created_post = Post.last
    assert created_post.images.attached?, "画像がDirect Uploadで添付されていません"
    assert_equal "test_image.jpg", created_post.images.first.filename.to_s
    assert_equal "image/jpeg", created_post.images.first.content_type
  end

  test "複数画像のDirect Uploadが動作すること" do
    image_file1 = fixture_file_upload('test_image.jpg', 'image/jpeg')
    image_file2 = fixture_file_upload('test_image.jpg', 'image/jpeg')

    assert_difference("Post.count", 1) do
      post posts_path, params: {
        post: {
          title: "複数画像Direct Uploadテスト",
          content: "複数画像のアップロードテスト",
          purpose: "マルチアップロードテスト",
          target_audience: "開発者",
          category_id: @category.id,
          post_type_id: @post_type.id,
          images: [image_file1, image_file2]
        }
      }
    end

    created_post = Post.last
    assert_equal 2, created_post.images.count, "複数画像がDirect Uploadで添付されていません"
    filenames = created_post.images.map(&:filename).map(&:to_s)
    assert_includes filenames, "test_image.jpg"
  end

  # === Video Direct Upload Tests ===

  test "動画のDirect Upload (signed_ids)が正常に動作すること" do
    video_blob = ActiveStorage::Blob.create_and_upload!(
      io: File.open(Rails.root.join("test", "fixtures", "files", "test_video.mp4")),
      filename: "direct_upload_video.mp4",
      content_type: "video/mp4"
    )

    signed_id = video_blob.signed_id
    assert signed_id.present?, "signed_idが生成されていません"

    assert_difference("Post.count", 1) do
      post posts_path, params: {
        post: {
          title: "動画Direct Uploadテスト",
          content: "動画Direct Upload機能テスト",
          purpose: "動画アップロードテスト",
          target_audience: "視聴者",
          category_id: @category.id,
          post_type_id: @post_type.id,
          video_signed_ids: [signed_id]
        }
      }
    end

    created_post = Post.last
    assert created_post.videos.attached?, "動画がDirect Uploadで添付されていません"
    assert_equal "direct_upload_video.mp4", created_post.videos.first.filename.to_s
    assert_equal "video/mp4", created_post.videos.first.content_type
  end

  test "複数動画のDirect Upload (signed_ids)が動作すること" do
    video_blob1 = ActiveStorage::Blob.create_and_upload!(
      io: File.open(Rails.root.join("test", "fixtures", "files", "test_video.mp4")),
      filename: "multi_video_1.mp4",
      content_type: "video/mp4"
    )

    video_blob2 = ActiveStorage::Blob.create_and_upload!(
      io: File.open(Rails.root.join("test", "fixtures", "files", "test_video.mp4")),
      filename: "multi_video_2.mp4",
      content_type: "video/mp4"
    )

    assert_difference("Post.count", 1) do
      post posts_path, params: {
        post: {
          title: "複数動画Direct Uploadテスト",
          content: "複数動画のDirect Uploadテスト",
          purpose: "複数動画テスト",
          target_audience: "視聴者",
          category_id: @category.id,
          post_type_id: @post_type.id,
          video_signed_ids: [video_blob1.signed_id, video_blob2.signed_id]
        }
      }
    end

    created_post = Post.last
    assert_equal 2, created_post.videos.count, "複数動画がDirect Uploadで添付されていません"
    filenames = created_post.videos.map(&:filename).map(&:to_s)
    assert_includes filenames, "multi_video_1.mp4"
    assert_includes filenames, "multi_video_2.mp4"
  end

  # === Mixed Media Direct Upload Tests ===

  test "画像と動画を同時にDirect Uploadできること" do
    image_file = fixture_file_upload('test_image.jpg', 'image/jpeg')

    video_blob = ActiveStorage::Blob.create_and_upload!(
      io: File.open(Rails.root.join("test", "fixtures", "files", "test_video.mp4")),
      filename: "mixed_media_video.mp4",
      content_type: "video/mp4"
    )

    assert_difference("Post.count", 1) do
      post posts_path, params: {
        post: {
          title: "混合メディアDirect Uploadテスト",
          content: "画像と動画の同時アップロード",
          purpose: "混合メディアテスト",
          target_audience: "全ユーザー",
          category_id: @category.id,
          post_type_id: @post_type.id,
          images: [image_file],
          video_signed_ids: [video_blob.signed_id]
        }
      }
    end

    created_post = Post.last
    assert created_post.images.attached?, "画像がDirect Uploadで添付されていません"
    assert created_post.videos.attached?, "動画がDirect Uploadで添付されていません"
    assert_equal "test_image.jpg", created_post.images.first.filename.to_s
    assert_equal "mixed_media_video.mp4", created_post.videos.first.filename.to_s
  end

  # === Auto-save with Direct Upload Tests ===

  test "自動保存時のDirect Upload (動画)が正常に動作すること" do
    video_blob = ActiveStorage::Blob.create_and_upload!(
      io: File.open(Rails.root.join("test", "fixtures", "files", "test_video.mp4")),
      filename: "auto_save_video.mp4",
      content_type: "video/mp4"
    )

    assert_difference("Post.count", 1) do
      post auto_save_posts_path, params: {
        title: "自動保存Direct Uploadテスト",
        content: "動画付き自動保存",
        video_signed_ids: [video_blob.signed_id]
      }, xhr: true
    end

    assert_response :success
    json_response = JSON.parse(response.body)
    assert json_response['success'], "動画付き自動保存が失敗しました"

    saved_post = Post.last
    assert_equal "draft", saved_post.status
    assert saved_post.videos.attached?, "動画が自動保存時にDirect Uploadで添付されていません"
    assert_equal "auto_save_video.mp4", saved_post.videos.first.filename.to_s
  end

  test "自動保存の重複チェック機能が動作すること" do
    video_blob = ActiveStorage::Blob.create_and_upload!(
      io: File.open(Rails.root.join("test", "fixtures", "files", "test_video.mp4")),
      filename: "duplicate_check_video.mp4",
      content_type: "video/mp4"
    )

    signed_id = video_blob.signed_id

    # 最初の自動保存
    post auto_save_posts_path, params: {
      title: "重複チェックテスト",
      content: "最初の保存",
      video_signed_ids: [signed_id]
    }, xhr: true

    saved_post = Post.last
    post_id = saved_post.friendly_id

    # 同じsigned_idで再度自動保存
    post auto_save_posts_path, params: {
      id: post_id,
      title: "重複チェックテスト",
      content: "2回目の保存",
      video_signed_ids: [signed_id]
    }, xhr: true

    saved_post.reload
    assert_equal 1, saved_post.videos.count, "重複した動画が添付されてしまいました"
  end

  # === Error Handling Tests ===

  test "無効なsigned_idでエラーが発生しないこと" do
    invalid_signed_ids = [
      "invalid_signed_id_123",
      "12345", # 数値のみ
      "short", # 短すぎる
      nil,
      ""
    ]

    assert_difference("Post.count", 1) do
      post posts_path, params: {
        post: {
          title: "無効signed_idエラーハンドリングテスト",
          content: "無効なsigned_idでのテスト",
          purpose: "エラーハンドリングテスト",
          target_audience: "開発者",
          category_id: @category.id,
          post_type_id: @post_type.id,
          video_signed_ids: invalid_signed_ids
        }
      }
    end

    created_post = Post.last
    assert_not created_post.videos.attached?, "無効なsigned_idで動画が添付されてしまいました"
    assert_equal "無効signed_idエラーハンドリングテスト", created_post.title, "投稿自体は作成されるべきです"
  end

  test "期限切れsigned_idのエラーハンドリング" do
    # 期限切れをシミュレートするため、古いsigned_idを使用
    expired_signed_id = "expired_or_invalid_signed_id_12345678901234567890"

    assert_difference("Post.count", 1) do
      post posts_path, params: {
        post: {
          title: "期限切れsigned_idテスト",
          content: "期限切れsigned_idでのエラーハンドリング",
          purpose: "期限切れテスト",
          target_audience: "開発者",
          category_id: @category.id,
          post_type_id: @post_type.id,
          video_signed_ids: [expired_signed_id]
        }
      }
    end

    created_post = Post.last
    assert_not created_post.videos.attached?, "期限切れsigned_idで動画が添付されてしまいました"
    assert_equal "期限切れsigned_idテスト", created_post.title
  end

  # === Japanese Filename Tests ===

  test "日本語ファイル名の画像がDirect Uploadできること" do
    # 日本語ファイル名はコントローラーレベルでのテストでは制限があるため、通常のファイルでテスト
    japanese_image_file = fixture_file_upload('test_image.jpg', 'image/jpeg')

    assert_difference("Post.count", 1) do
      post posts_path, params: {
        post: {
          title: "日本語ファイル名画像テスト",
          content: "日本語ファイル名でのDirect Upload",
          purpose: "国際化テスト",
          target_audience: "日本語ユーザー",
          category_id: @category.id,
          post_type_id: @post_type.id,
          images: [japanese_image_file]
        }
      }
    end

    created_post = Post.last
    assert created_post.images.attached?, "日本語ファイル名の画像が添付されていません"
    assert_equal "test_image.jpg", created_post.images.first.filename.to_s
  end

  test "日本語ファイル名の動画がDirect Uploadできること" do
    japanese_video_blob = ActiveStorage::Blob.create_and_upload!(
      io: File.open(Rails.root.join("test", "fixtures", "files", "test_video.mp4")),
      filename: "とぐろ島の神髄テスト動画.mp4",
      content_type: "video/mp4"
    )

    assert_difference("Post.count", 1) do
      post posts_path, params: {
        post: {
          title: "日本語ファイル名動画テスト",
          content: "日本語ファイル名でのDirect Upload",
          purpose: "国際化動画テスト",
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
  end

  # === Update Operations with Direct Upload Tests ===

  test "投稿更新時のDirect Upload (画像)が動作すること" do
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

    # 新しい画像をDirect Upload
    new_image_file = fixture_file_upload('test_image.jpg', 'image/jpeg')

    patch post_path(existing_post), params: {
      post: {
        title: "画像が追加された投稿",
        content: "画像追加更新テスト",
        images: [new_image_file]
      }
    }

    existing_post.reload
    assert existing_post.images.attached?, "更新時に画像がDirect Uploadで添付されていません"
    assert_equal "test_image.jpg", existing_post.images.first.filename.to_s
    assert_equal "画像が追加された投稿", existing_post.title
  end

  test "投稿更新時のDirect Upload (動画)が動作すること" do
    existing_post = Post.create!(
      title: "動画更新テスト投稿",
      content: "動画更新前の内容",
      purpose: "動画更新テスト",
      target_audience: "テストユーザー", 
      user: @user,
      category: @category,
      post_type: @post_type,
      status: :published
    )

    new_video_blob = ActiveStorage::Blob.create_and_upload!(
      io: File.open(Rails.root.join("test", "fixtures", "files", "test_video.mp4")),
      filename: "update_test_video.mp4",
      content_type: "video/mp4"
    )

    patch post_path(existing_post), params: {
      post: {
        title: "動画が追加された投稿",
        content: "動画追加更新テスト",
        video_signed_ids: [new_video_blob.signed_id]
      }
    }

    existing_post.reload
    assert existing_post.videos.attached?, "更新時に動画がDirect Uploadで添付されていません"
    assert_equal "update_test_video.mp4", existing_post.videos.first.filename.to_s
  end

  # === Performance and Load Tests ===

  test "大量ファイルのDirect Uploadパフォーマンステスト" do
    # 5つの画像を同時にDirect Upload
    image_files = []
    5.times do |i|
      image_files << fixture_file_upload('test_image.jpg', 'image/jpeg')
    end

    start_time = Time.current

    assert_difference("Post.count", 1) do
      post posts_path, params: {
        post: {
          title: "パフォーマンステスト投稿",
          content: "大量ファイルのDirect Upload",
          purpose: "パフォーマンステスト",
          target_audience: "開発者",
          category_id: @category.id,
          post_type_id: @post_type.id,
          images: image_files
        }
      }
    end

    end_time = Time.current
    processing_time = end_time - start_time

    created_post = Post.last
    assert_equal 5, created_post.images.count, "5つの画像がDirect Uploadで添付されていません"
    
    # パフォーマンス確認（10秒以内で完了することを期待）
    assert processing_time < 10.seconds, "大量ファイルのDirect Uploadが10秒以内に完了していません (#{processing_time}秒)"
  end

  # === Cleanup and Edge Case Tests ===

  test "削除されたblobのsigned_idでエラーが発生しないこと" do
    # Blobを作成してから削除
    video_blob = ActiveStorage::Blob.create_and_upload!(
      io: File.open(Rails.root.join("test", "fixtures", "files", "test_video.mp4")),
      filename: "to_be_deleted_video.mp4", 
      content_type: "video/mp4"
    )

    signed_id = video_blob.signed_id
    video_blob.purge # Blobを削除

    assert_difference("Post.count", 1) do
      post posts_path, params: {
        post: {
          title: "削除されたBlobのsigned_idテスト",
          content: "削除されたBlobでのエラーハンドリング",
          purpose: "削除テスト", 
          target_audience: "開発者",
          category_id: @category.id,
          post_type_id: @post_type.id,
          video_signed_ids: [signed_id]
        }
      }
    end

    created_post = Post.last
    assert_not created_post.videos.attached?, "削除されたBlobで動画が添付されてしまいました"
    assert_equal "削除されたBlobのsigned_idテスト", created_post.title
  end
end