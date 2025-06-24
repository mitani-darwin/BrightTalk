# test/models/post_tag_test.rb
require "test_helper"

class PostTagTest < ActiveSupport::TestCase
  def setup
    @post = posts(:first_post)
    @tag = Tag.create!(name: "テストタグ")
  end

  test "有効な属性で投稿タグが有効であること" do
    post_tag = PostTag.new(
      post: @post,
      tag: @tag
    )
    assert post_tag.valid?, "PostTag should be valid but got errors: #{post_tag.errors.full_messages}"
  end

  test "投稿が必須であること" do
    post_tag = PostTag.new(
      post: nil,
      tag: @tag
    )
    assert_not post_tag.valid?
    assert post_tag.errors[:post].present?
    # エラーメッセージが存在することのみを確認
  end

  test "タグが必須であること" do
    post_tag = PostTag.new(
      post: @post,
      tag: nil
    )
    assert_not post_tag.valid?
    assert post_tag.errors[:tag].present?
    # エラーメッセージが存在することのみを確認
  end

  test "同じ投稿に同じタグを重複して付けられないこと" do
    # 最初の関連付けを作成
    PostTag.create!(
      post: @post,
      tag: @tag
    )

    # 同じ組み合わせで2つ目を作成しようとする
    duplicate_post_tag = PostTag.new(
      post: @post,
      tag: @tag
    )

    assert_not duplicate_post_tag.valid?
    assert duplicate_post_tag.errors[:post_id].present?
  end

  test "投稿との関連付けが正しく動作すること" do
    post_tag = PostTag.new(
      post: @post,
      tag: @tag
    )
    assert_equal @post, post_tag.post
  end

  test "タグとの関連付けが正しく動作すること" do
    post_tag = PostTag.new(
      post: @post,
      tag: @tag
    )
    assert_equal @tag, post_tag.tag
  end

  test "バリデーションエラーがあることを確認" do
    post_tag = PostTag.new(post: nil, tag: nil)
    assert_not post_tag.valid?
    assert post_tag.errors[:post].present?
    assert post_tag.errors[:tag].present?
  end

  test "異なる投稿に同じタグを付けられること" do
    # 別の投稿を作成
    another_post = Post.create!(
      title: "Another Post",
      content: "Another content",
      user: users(:test_user),
      category: categories(:general)
    )

    # 最初の投稿にタグを関連付け
    post_tag1 = PostTag.create!(
      post: @post,
      tag: @tag
    )

    # 別の投稿に同じタグを関連付け
    post_tag2 = PostTag.new(
      post: another_post,
      tag: @tag
    )

    assert post_tag2.valid?, "PostTag should be valid but got errors: #{post_tag2.errors.full_messages}"
  end

  test "同じ投稿に異なるタグを付けられること" do
    # 別のタグを作成
    another_tag = Tag.create!(name: "別のテストタグ")

    # 最初のタグを関連付け
    post_tag1 = PostTag.create!(
      post: @post,
      tag: @tag
    )

    # 同じ投稿に別のタグを関連付け
    post_tag2 = PostTag.new(
      post: @post,
      tag: another_tag
    )

    assert post_tag2.valid?, "PostTag should be valid but got errors: #{post_tag2.errors.full_messages}"
  end

  test "投稿とタグの組み合わせが一意であること" do
    # 最初の関連付けを作成
    PostTag.create!(post: @post, tag: @tag)

    # 同じ組み合わせで2つ目を作成
    duplicate = PostTag.new(post: @post, tag: @tag)

    assert_not duplicate.valid?
    # post_idのuniqueバリデーションエラーが発生すること
    assert duplicate.errors.any?
  end
end