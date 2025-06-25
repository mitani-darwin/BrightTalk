require "test_helper"

class CommentTest < ActiveSupport::TestCase
  def setup
    @user = users(:test_user)
    @post = posts(:first_post)
  end

  test "有効な属性でコメントが有効であること" do
    comment = Comment.new(
      content: "テストコメント",
      user: @user,
      post: @post
    )
    assert comment.valid?, "Comment should be valid but got errors: #{comment.errors.full_messages}"
  end

  test "コンテンツが必須であること" do
    comment = Comment.new(
      content: nil,
      user: @user,
      post: @post
    )
    assert_not comment.valid?
    assert comment.errors[:content].present?
  end

  test "コンテンツが空文字列の場合無効であること" do
    comment = Comment.new(
      content: "",
      user: @user,
      post: @post
    )
    assert_not comment.valid?
    assert comment.errors[:content].present?
  end

  test "ユーザーが必須であること" do
    comment = Comment.new(
      content: "テストコメント",
      user: nil,
      post: @post
    )
    assert_not comment.valid?
    assert comment.errors[:user].present?
  end

  test "投稿が必須であること" do
    comment = Comment.new(
      content: "テストコメント",
      user: @user,
      post: nil
    )
    assert_not comment.valid?
    assert comment.errors[:post].present?
  end

  test "ユーザーとの関連付けが正しく動作すること" do
    comment = Comment.new(
      content: "テストコメント",
      user: @user,
      post: @post
    )
    assert_equal @user, comment.user
    # フィクスチャのname属性がnilの場合に対応
    if @user.name.nil?
      assert_nil comment.user.name
    else
      assert_equal @user.name, comment.user.name
    end
  end

  test "投稿との関連付けが正しく動作すること" do
    comment = Comment.new(
      content: "テストコメント",
      user: @user,
      post: @post
    )
    assert_equal @post, comment.post
    assert_equal @post.title, comment.post.title
  end

  test "コメントの文字数制限が正しく動作すること" do
    long_content = "a" * 501 # 500文字制限を超える場合
    comment = Comment.new(
      content: long_content,
      user: @user,
      post: @post
    )
    assert_not comment.valid?
    assert comment.errors[:content].present?
  end

  test "作成時間が自動的に設定されること" do
    comment = Comment.create!(
      content: "テストコメント",
      user: @user,
      post: @post
    )
    assert_not_nil comment.created_at
    assert_not_nil comment.updated_at
  end
end