# test/models/category_test.rb
require "test_helper"

class CategoryTest < ActiveSupport::TestCase
  test "有効な属性でカテゴリが有効であること" do
    category = Category.new(name: "テストカテゴリ")
    assert category.valid?, "Category should be valid but got errors: #{category.errors.full_messages}"
  end

  test "名前が必須であること" do
    category = Category.new(name: nil)
    assert_not category.valid?
    assert category.errors[:name].present?
  end

  test "名前が空文字列の場合無効であること" do
    category = Category.new(name: "")
    assert_not category.valid?
    assert category.errors[:name].present?
  end

  test "名前が一意であること" do
    existing_category = categories(:general)
    duplicate_category = Category.new(name: existing_category.name)
    assert_not duplicate_category.valid?
    assert duplicate_category.errors[:name].present?
  end

  test "投稿との関連付けが正しく動作すること" do
    category = categories(:general)
    assert_respond_to category, :posts
    assert category.posts.is_a?(ActiveRecord::Associations::CollectionProxy)
  end

  test "カテゴリ削除時に関連する投稿が適切に処理されること" do
    category = categories(:general)
    post_count_before = category.posts.count

    if post_count_before > 0
      # dependent: :destroyが設定されているため、投稿も一緒に削除される
      assert_difference("Post.count", -post_count_before) do
        category.destroy
      end
    else
      # 投稿がない場合は、Post.countは変化しない
      assert_difference("Post.count", 0) do
        category.destroy
      end
    end
  end

  test "新しいカテゴリが作成できること" do
    assert_difference("Category.count", 1) do
      Category.create!(name: "新しいカテゴリ")
    end
  end

  test "カテゴリに投稿を関連付けできること" do
    category = Category.create!(name: "テストカテゴリ")
    user = users(:test_user)

    post = Post.create!(
      title: "テスト投稿",
      content: "テスト内容",
      purpose: "テスト目的",
      target_audience: "テスト対象者",
      post_type: post_types(:tutorial),
      user: user,
      category: category
    )

    assert_includes category.posts, post
    assert_equal category, post.category
  end

  test "カテゴリ名の長さ制限" do
    # 50文字以下は有効
    valid_category = Category.new(name: "a" * 50)
    assert valid_category.valid?, "Category with 50 characters should be valid"

    # 51文字以上は無効
    invalid_category = Category.new(name: "a" * 51)
    assert_not invalid_category.valid?, "Category with 51 characters should be invalid"
    assert invalid_category.errors[:name].present?, "Should have length validation error"
  end

  test "with_postsスコープが正しく動作すること" do
    # 投稿を持つカテゴリのみが取得されることを確認
    categories_with_posts = Category.with_posts
    assert categories_with_posts.is_a?(ActiveRecord::Relation)

    # 実際に投稿を持つカテゴリを作成してテスト
    category = Category.create!(name: "投稿ありカテゴリ")
    user = users(:test_user)

    Post.create!(
      title: "テスト投稿",
      content: "テスト内容",
      purpose: "テスト目的",
      target_audience: "テスト対象者",
      post_type: post_types(:tutorial),
      user: user,
      category: category
    )

    assert_includes Category.with_posts, category
  end

  test "カテゴリ削除時のdependent destroyの動作確認" do
    # 新しいカテゴリと投稿を作成
    category = Category.create!(name: "削除テストカテゴリ")
    user = users(:test_user)

    post1 = Post.create!(
      title: "削除テスト投稿1",
      content: "テスト内容1",
      purpose: "削除テスト目的1",
      target_audience: "削除テスト対象者1",
      post_type: post_types(:tutorial),
      user: user,
      category: category
    )

    post2 = Post.create!(
      title: "削除テスト投稿2",
      content: "テスト内容2",
      purpose: "削除テスト目的2",
      target_audience: "削除テスト対象者2",
      post_type: post_types(:technical_note),
      user: user,
      category: category
    )

    # カテゴリを削除すると、関連する投稿も削除される
    assert_difference("Post.count", -2) do
      assert_difference("Category.count", -1) do
        category.destroy
      end
    end
  end

  test "空のカテゴリを削除してもPostが影響されないこと" do
    # 投稿を持たないカテゴリを作成
    empty_category = Category.create!(name: "空のカテゴリ")

    # このカテゴリを削除してもPost.countは変化しない
    assert_difference("Post.count", 0) do
      assert_difference("Category.count", -1) do
        empty_category.destroy
      end
    end
  end

  test "カテゴリ名の境界値テスト" do
    # 1文字は有効
    category_1_char = Category.new(name: "a")
    assert category_1_char.valid?, "Category with 1 character should be valid"

    # 50文字ちょうどは有効
    category_50_chars = Category.new(name: "a" * 50)
    assert category_50_chars.valid?, "Category with exactly 50 characters should be valid"

    # 51文字は無効
    category_51_chars = Category.new(name: "a" * 51)
    assert_not category_51_chars.valid?, "Category with 51 characters should be invalid"

    # nameフィールドに長さに関するエラーがあることを確認
    assert category_51_chars.errors[:name].present?, "Should have name validation error"

    # エラーメッセージに「50」と「文字」が含まれていることを確認（言語に関係なく）
    error_message = category_51_chars.errors[:name].first
    assert error_message.include?("50"), "Error message should mention 50: #{error_message}"
    assert (error_message.include?("文字") || error_message.include?("character")),
           "Error message should mention character limit: #{error_message}"
  end

  test "カテゴリの投稿数カウント" do
    category = Category.create!(name: "カウントテストカテゴリ")
    user = users(:test_user)

    # 最初は0件
    assert_equal 0, category.posts.count

    # 投稿を追加
    Post.create!(
      title: "カウントテスト投稿1",
      content: "テスト内容1",
      purpose: "テスト目的",
      target_audience: "テスト対象者",
      post_type: post_types(:tutorial),
      user: user,
      category: category
    )

    assert_equal 1, category.posts.count

    # さらに投稿を追加
    Post.create!(
      title: "カウントテスト投稿2",
      content: "テスト内容2",
      purpose: "テスト目的2",
      target_audience: "テスト対象者2",
      post_type: post_types(:technical_note),
      user: user,
      category: category
    )

    assert_equal 2, category.posts.count
  end
end
