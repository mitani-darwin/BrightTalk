
require "test_helper"

class PostTest < ActiveSupport::TestCase
  def setup
    @user = users(:test_user)
    @category = categories(:general)
  end

  test "有効な属性で投稿が有効であること" do
    post = Post.new(
      title: "Test Post",
      content: "This is a test post content.",
      purpose: "Test purpose",
      target_audience: "Test audience",
      user: @user,
      category: @category,
      post_type: post_types(:tutorial)
    )
    assert post.valid?, "Post should be valid but got errors: #{post.errors.full_messages}"
  end

  test "タイトルが必須であること" do
    post = Post.new(
      content: "This is a test post content.",
      user: @user,
      category: @category
    )
    assert_not post.valid?
    assert_includes post.errors[:title], "を入力してください"
  end

  test "内容が必須であること" do
    post = Post.new(
      title: "Test Post",
      user: @user,
      category: @category
    )
    assert_not post.valid?
    assert_includes post.errors[:content], "を入力してください"
  end

  test "ユーザーが必須であること" do
    post = Post.new(
      title: "Test Post",
      content: "This is a test post content.",
      category: @category
    )
    assert_not post.valid?
    # 日本語化されたエラーメッセージに対応
    user_errors = post.errors[:user]
    assert user_errors.any? { |error| error.include?("Translation missing") || error.include?("must exist") || error.include?("を入力してください") }
  end

  test "カテゴリーがオプションの場合は必須でないこと" do
    post = Post.new(
      title: "Test Post",
      content: "This is a test post content.",
      user: @user,
      status: :draft
      # categoryは設定しない
    )
    # 下書きの場合はカテゴリーがoptionalなので、バリデーションエラーにはならない
    assert post.valid?, "Post should be valid without category but got errors: #{post.errors.full_messages}"
  end

  # === Attachment Tests ===

  test "画像を添付できること" do
    post = create_valid_post

    # 画像ファイルを添付
    post.images.attach(
      io: File.open(Rails.root.join("test", "fixtures", "files", "test_image.jpg")),
      filename: "test_image.jpg",
      content_type: "image/jpeg"
    )

    assert post.images.attached?, "画像が添付されていません"
    assert_equal 1, post.images.count
    assert_equal "test_image.jpg", post.images.first.filename.to_s
    assert_equal "image/jpeg", post.images.first.content_type
  end

  test "動画を添付できること" do
    post = create_valid_post

    # 動画ファイルを添付
    post.videos.attach(
      io: File.open(Rails.root.join("test", "fixtures", "files", "test_video.mp4")),
      filename: "test_video.mp4",
      content_type: "video/mp4"
    )

    assert post.videos.attached?, "動画が添付されていません"
    assert_equal 1, post.videos.count
    assert_equal "test_video.mp4", post.videos.first.filename.to_s
    assert_equal "video/mp4", post.videos.first.content_type
  end

  test "複数の画像を添付できること" do
    post = create_valid_post

    # 複数の画像を添付
    post.images.attach(
      io: File.open(Rails.root.join("test", "fixtures", "files", "test_image.jpg")),
      filename: "test_image1.jpg",
      content_type: "image/jpeg"
    )
    post.images.attach(
      io: File.open(Rails.root.join("test", "fixtures", "files", "test_image.jpg")),
      filename: "test_image2.jpg",
      content_type: "image/jpeg"
    )

    assert post.images.attached?, "画像が添付されていません"
    assert_equal 2, post.images.count, "画像の数が期待値と異なります"
  end

  test "日本語ファイル名の画像を添付できること" do
    post = create_valid_post

    # 日本語ファイル名の画像を添付
    post.images.attach(
      io: File.open(Rails.root.join("test", "fixtures", "files", "test_image.jpg")),
      filename: "テスト画像.jpg",
      content_type: "image/jpeg"
    )

    assert post.images.attached?, "日本語ファイル名の画像が添付されていません"
    assert_equal "テスト画像.jpg", post.images.first.filename.to_s
  end

  test "日本語ファイル名の動画を添付できること" do
    post = create_valid_post

    # 日本語ファイル名の動画を添付
    post.videos.attach(
      io: File.open(Rails.root.join("test", "fixtures", "files", "test_video.mp4")),
      filename: "とぐろ島の神髄テスト.mp4",
      content_type: "video/mp4"
    )

    assert post.videos.attached?, "日本語ファイル名の動画が添付されていません"
    assert_equal "とぐろ島の神髄テスト.mp4", post.videos.first.filename.to_s
  end

  test "auto_saved_draft?メソッドが正しく動作すること" do
    post = create_valid_post
    post.status = :draft
    post.auto_save = true

    assert post.auto_saved_draft?, "auto_saved_draft?がtrueを返すべきです"

    post.auto_save = false
    assert_not post.auto_saved_draft?, "auto_saved_draft?がfalseを返すべきです"

    post.status = :published
    post.auto_save = true
    assert_not post.auto_saved_draft?, "公開済みの場合はfalseを返すべきです"
  end

  test "自動保存時はバリデーションがスキップされること" do
    post = Post.new(
      title: "", # 空のタイトル（通常は無効）
      content: "", # 空の内容（通常は無効）
      user: @user,
      status: :draft,
      auto_save: true
    )

    assert post.auto_saved_draft?, "auto_saved_draft?がtrueであるべきです"
    # auto_saved_draft?がtrueの場合、バリデーションはスキップされる
    assert post.valid?, "自動保存時はバリデーションがスキップされるべきです"
  end

  test "投稿のステータスがenumで管理されていること" do
    post = create_valid_post

    # デフォルトは公開状態
    assert_equal "published", post.status

    # 下書きに変更
    post.draft!
    assert_equal "draft", post.status
    assert post.draft?

    # 公開に戻す
    post.published!
    assert_equal "published", post.status
    assert post.published?
  end

  test "関連投稿の取得が正しく動作すること" do
    post = create_valid_post
    post.save!

    # 同じカテゴリの他の投稿を作成
    related_post = Post.create!(
      title: "関連投稿",
      content: "関連投稿の内容",
      purpose: "関連テスト",
      target_audience: "テストユーザー",
      user: @user,
      category: @category,
      post_type: post_types(:tutorial),
      status: :published
    )

    related_posts = post.related_posts(limit: 5)
    assert_includes related_posts, related_post, "同じカテゴリの投稿が関連投稿に含まれるべきです"
  end

  test "content_as_htmlメソッドが正しくMarkdownを処理すること" do
    post = create_valid_post
    post.content = "# テストタイトル\n\nテスト内容です。"
    post.save!

    html_content = post.content_as_html
    assert html_content.present?, "HTMLコンテンツが生成されるべきです"
    # 実際のHTML変換の詳細はApplicationController.helpersに依存するため、
    # ここでは空でないことのみ確認
  end

  test "previous_post_by_authorメソッドが正しく動作すること" do
    # 専用のテストユーザーを作成（fixtureとの競合を避ける）
    test_user = User.create!(
      name: "Previous Post Test User",
      email: "previous_post_test@example.com",
      confirmed_at: Time.current
    )

    # 最初の投稿（1日前）
    first_post = Post.create!(
      title: "Previous Test First Post",
      content: "Previous test first post content",
      purpose: "Previous test purpose",
      target_audience: "Previous test audience",
      user: test_user,
      category: @category,
      post_type: post_types(:tutorial),
      status: :published,
      created_at: 1.day.ago
    )

    # 2番目の投稿（現在時刻）
    second_post = Post.create!(
      title: "Previous Test Second Post",
      content: "Previous test second post content",
      purpose: "Previous test purpose 2",
      target_audience: "Previous test audience 2",
      user: test_user,
      category: @category,
      post_type: post_types(:tutorial),
      status: :published,
      created_at: Time.current
    )

    # 2番目の投稿から見た前の投稿は1番目であるべき
    previous = second_post.previous_post_by_author
    assert_equal first_post, previous, "前の投稿が正しく取得されるべきです"
  end

  test "next_post_by_authorメソッドが正しく動作すること" do
    # 専用のテストユーザーを作成（fixtureとの競合を避ける）
    test_user = User.create!(
      name: "Next Post Test User",
      email: "next_post_test@example.com",
      confirmed_at: Time.current
    )

    # 最初の投稿（1日前）
    first_post = Post.create!(
      title: "Next Test First Post",
      content: "Next test first post content",
      purpose: "Next test purpose",
      target_audience: "Next test audience",
      user: test_user,
      category: @category,
      post_type: post_types(:tutorial),
      status: :published,
      created_at: 1.day.ago
    )

    # 2番目の投稿（現在時刻）
    second_post = Post.create!(
      title: "Next Test Second Post",
      content: "Next test second post content",
      purpose: "Next test purpose 2",
      target_audience: "Next test audience 2",
      user: test_user,
      category: @category,
      post_type: post_types(:tutorial),
      status: :published,
      created_at: Time.current
    )

    # 1番目の投稿から見た次の投稿は2番目であるべき
    next_post = first_post.next_post_by_author
    assert_equal second_post, next_post, "次の投稿が正しく取得されるべきです"
  end

  private

  def create_valid_post
    Post.new(
      title: "Test Post",
      content: "This is a test post content.",
      purpose: "Test purpose",
      target_audience: "Test audience",
      user: @user,
      category: @category,
      post_type: post_types(:tutorial)
    )
  end
end
