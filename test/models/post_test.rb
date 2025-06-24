
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
      user: @user,
      category: @category
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
      user: @user
      # categoryは設定しない
    )
    # カテゴリーがoptionalなので、バリデーションエラーにはならない
    assert post.valid?, "Post should be valid without category but got errors: #{post.errors.full_messages}"
  end
end