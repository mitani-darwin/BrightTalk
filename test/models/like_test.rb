# test/models/like_test.rb
require "test_helper"

class LikeTest < ActiveSupport::TestCase
  def setup
    @user = users(:test_user)
    @post = posts(:first_post)
    @another_user = users(:another_user)
  end

  def teardown
    # 各テスト後にクリーンアップ
    Like.where(user: [ @user, @another_user ], post: @post).destroy_all
  end

  test "有効な属性でいいねが有効であること" do
    # 既存のいいねをクリア
    Like.where(user: @user, post: @post).destroy_all

    like = Like.new(
      user: @user,
      post: @post
    )
    assert like.valid?, "Like should be valid but got errors: #{like.errors.full_messages}"
  end

  test "ユーザーが必須であること" do
    like = Like.new(
      user: nil,
      post: @post
    )
    assert_not like.valid?
    assert like.errors[:user].present?
  end

  test "投稿が必須であること" do
    like = Like.new(
      user: @user,
      post: nil
    )
    assert_not like.valid?
    assert like.errors[:post].present?
  end

  test "同じユーザーが同じ投稿に重複していいねできないこと" do
    # 既存のいいねをクリア
    Like.where(user: @user, post: @post).destroy_all

    # 最初のいいねを作成
    like1 = Like.new(
      user: @user,
      post: @post
    )
    like1.save!

    # 同じユーザーが同じ投稿に再度いいねしようとする
    like2 = Like.new(
      user: @user,
      post: @post
    )

    assert_not like2.valid?
    # 重複エラーが発生すること
    assert like2.errors[:user_id].present?
  end

  test "異なるユーザーが同じ投稿にいいねできること" do
    # 既存のいいねをクリア
    Like.where(user: [ @user, @another_user ], post: @post).destroy_all

    # 最初のユーザーがいいね
    like1 = Like.new(
      user: @user,
      post: @post
    )
    like1.save!

    # 別のユーザーが同じ投稿にいいね
    like2 = Like.new(
      user: @another_user,
      post: @post
    )

    assert like2.valid?, "Like should be valid but got errors: #{like2.errors.full_messages}"
  end

  test "同じユーザーが異なる投稿にいいねできること" do
    # 既存のいいねをクリア
    Like.where(user: @user, post: @post).destroy_all

    # 別の投稿を作成
    another_post = Post.create!(
      title: "Another Post",
      content: "Another content",
      user: @user,
      category: categories(:general)
    )

    # 最初の投稿にいいね
    like1 = Like.new(
      user: @user,
      post: @post
    )
    like1.save!

    # 別の投稿にいいね
    like2 = Like.new(
      user: @user,
      post: another_post
    )

    assert like2.valid?, "Like should be valid but got errors: #{like2.errors.full_messages}"
  end

  test "ユーザーとの関連付けが正しく動作すること" do
    like = Like.new(
      user: @user,
      post: @post
    )
    assert_equal @user, like.user
  end

  test "投稿との関連付けが正しく動作すること" do
    like = Like.new(
      user: @user,
      post: @post
    )
    assert_equal @post, like.post
  end

  test "作成時間が自動的に設定されること" do
    # 既存のいいねをクリア
    Like.where(user: @user, post: @post).destroy_all

    like = Like.create!(
      user: @user,
      post: @post
    )
    assert_not_nil like.created_at
    assert_not_nil like.updated_at
  end

  test "バリデーションエラーがあることを確認" do
    like = Like.new(user: nil, post: nil)
    assert_not like.valid?
    assert like.errors[:user].present?
    assert like.errors[:post].present?
  end

  test "重複バリデーションメッセージの確認" do
    # 既存のいいねをクリア
    Like.where(user: @user, post: @post).destroy_all

    # 最初のいいねを作成
    Like.create!(user: @user, post: @post)

    # 重複を試す
    duplicate_like = Like.new(user: @user, post: @post)

    assert_not duplicate_like.valid?
    # user_idに対するuniquenessバリデーションエラーが発生
    assert duplicate_like.errors[:user_id].present?
  end

  test "Likeレコードの削除が正しく動作すること" do
    # 既存のいいねをクリア
    Like.where(user: @user, post: @post).destroy_all

    like = Like.create!(
      user: @user,
      post: @post
    )

    assert_difference("Like.count", -1) do
      like.destroy!
    end
  end

  test "複数のユーザーが同じ投稿にいいねできる" do
    # 既存のいいねをクリア
    Like.where(user: [ @user, @another_user ], post: @post).destroy_all

    # 両方のユーザーがいいねできる
    like1 = Like.create!(user: @user, post: @post)
    like2 = Like.create!(user: @another_user, post: @post)

    assert like1.persisted?
    assert like2.persisted?
    assert_not_equal like1.user, like2.user
    assert_equal like1.post, like2.post
  end

  test "同じユーザーが複数の投稿にいいねできる" do
    # 既存のいいねをクリア（念のため）
    Like.where(user: @user).destroy_all

    # 新しい投稿を作成
    post2 = Post.create!(
      title: "Post 2 #{Time.current.to_i}",
      content: "Content 2",
      user: @user,
      category: categories(:general)
    )

    begin
      # 同じユーザーが複数の投稿にいいねできる
      like1 = Like.create!(user: @user, post: @post)
      like2 = Like.create!(user: @user, post: post2)

      assert like1.persisted?
      assert like2.persisted?
      assert_equal like1.user, like2.user
      assert_not_equal like1.post, like2.post
    ensure
      # クリーンアップ
      Like.where(user: @user, post: [ @post, post2 ]).destroy_all
      post2.destroy
    end
  end

  test "save! 実行時の重複エラーハンドリング" do
    # 既存のいいねをクリア
    Like.where(user: @user, post: @post).destroy_all

    # 最初のいいねを作成
    Like.create!(user: @user, post: @post)

    # 重複で例外が発生することを確認
    duplicate_like = Like.new(user: @user, post: @post)

    # saveでfalseが返されることを確認
    assert_not duplicate_like.save

    # save!で例外が発生することを確認
    assert_raises(ActiveRecord::RecordInvalid) do
      Like.create!(user: @user, post: @post)
    end
  end

  test "基本的ないいね機能" do
    # 全てのいいねをクリア
    Like.destroy_all

    # いいね作成
    like = Like.new(user: @user, post: @post)
    assert like.valid?, "Like should be valid: #{like.errors.full_messages}"

    assert like.save, "Like should save successfully"
    assert like.persisted?, "Like should be persisted"

    # 重複テスト
    duplicate = Like.new(user: @user, post: @post)
    assert_not duplicate.valid?, "Duplicate like should not be valid"
    assert duplicate.errors[:user_id].present?, "Should have uniqueness error"
  end
end
