# test/models/tag_test.rb
require "test_helper"

class TagTest < ActiveSupport::TestCase
  test "有効な属性でタグが有効であること" do
    tag = Tag.new(name: "テストタグ")
    assert tag.valid?, "Tag should be valid but got errors: #{tag.errors.full_messages}"
  end

  test "名前が必須であること" do
    tag = Tag.new(name: nil)
    assert_not tag.valid?
    assert tag.errors[:name].present?
  end

  test "名前が空文字列の場合無効であること" do
    tag = Tag.new(name: "")
    assert_not tag.valid?
    assert tag.errors[:name].present?
  end

  test "名前が一意であること" do
    Tag.create!(name: "既存タグ")
    duplicate_tag = Tag.new(name: "既存タグ")
    assert_not duplicate_tag.valid?
    assert duplicate_tag.errors[:name].present?
  end

  test "投稿との多対多関連付けが正しく動作すること" do
    tag = Tag.create!(name: "テストタグ")
    post = posts(:first_post)

    # 関連付け
    tag.post_tags.create!(post: post)

    assert_includes tag.posts, post
    assert_includes post.tags, tag
  end

  test "新しいタグが作成できること" do
    assert_difference("Tag.count", 1) do
      Tag.create!(name: "新しいタグ")
    end
  end

  test "タグ名の長さ制限が正しく動作すること" do
    long_name = "a" * 31 # 30文字制限を超える場合
    tag = Tag.new(name: long_name)
    assert_not tag.valid?
    assert tag.errors[:name].present?
  end

  test "find_or_create_by_namesが正しく動作すること" do
    tag_names = [ "タグ1", "タグ2", "既存タグ" ]

    # 既存タグを事前に作成
    existing_tag = Tag.create!(name: "既存タグ")

    tags = Tag.find_or_create_by_names(tag_names)

    assert_equal 3, tags.length
    assert_equal "タグ1", tags[0].name
    assert_equal "タグ2", tags[1].name
    assert_equal existing_tag, tags[2] # 既存のタグが返される
  end

  test "複数の投稿に同じタグを付けられること" do
    tag = Tag.create!(name: "共通タグ")
    post1 = posts(:first_post)

    # 別の投稿を作成
    post2 = Post.create!(
      title: "Second Post",
      content: "Second content",
      purpose: "セカンドテスト目的",
      target_audience: "セカンドテスト対象者",
      post_type: post_types(:tutorial),
      user: users(:test_user),
      category: categories(:general)
    )

    # 両方の投稿に同じタグを付ける
    tag.post_tags.create!(post: post1)
    tag.post_tags.create!(post: post2)

    assert_includes tag.posts, post1
    assert_includes tag.posts, post2
    assert_equal 2, tag.posts.count
  end

  test "popular_for_postsスコープが正しく動作すること" do
    # テスト用のタグと投稿を作成
    popular_tag = Tag.create!(name: "人気タグ")
    normal_tag = Tag.create!(name: "普通タグ")

    user = users(:test_user)
    category = categories(:general)

    # 人気タグに複数の投稿を関連付け
    3.times do |i|
      post = Post.create!(
        title: "Post #{i}",
        content: "Content #{i}",
        purpose: "テスト目的 #{i}",
        target_audience: "テスト対象者",
        post_type: post_types(:tutorial),
        user: user,
        category: category
      )
      popular_tag.post_tags.create!(post: post)
    end

    # 普通タグに1つの投稿を関連付け
    post = Post.create!(
      title: "Normal Post",
      content: "Normal Content",
      purpose: "普通のテスト目的",
      target_audience: "普通のテスト対象者",
      post_type: post_types(:tutorial),
      user: user,
      category: category
    )
    normal_tag.post_tags.create!(post: post)

    # popular_for_postsスコープをテスト
    popular_tags = Tag.popular_for_posts.limit(2)
    assert_includes popular_tags, popular_tag
  end

  test "スペースを含むタグ名の処理" do
    tag_names = [ " タグ1 ", "  タグ2  " ]
    tags = Tag.find_or_create_by_names(tag_names)

    assert_equal "タグ1", tags[0].name
    assert_equal "タグ2", tags[1].name
  end
end
