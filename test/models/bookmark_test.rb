# test/models/bookmark_test.rb
require "test_helper"

class BookmarkTest < ActiveSupport::TestCase
  def setup
    @user = users(:test_user)
    @another_user = users(:another_user)
    @post = posts(:first_post)
  end

  def teardown
    Bookmark.where(user: [ @user, @another_user ], post: @post).destroy_all
  end

  test "有効な属性でブックマークが作成できること" do
    Bookmark.where(user: @user, post: @post).destroy_all

    bookmark = Bookmark.new(user: @user, post: @post)
    assert bookmark.valid?, "Expected bookmark to be valid but had errors: #{bookmark.errors.full_messages}"
  end

  test "ユーザーが必須であること" do
    bookmark = Bookmark.new(user: nil, post: @post)
    assert_not bookmark.valid?
    assert_includes bookmark.errors[:user], "must exist"
  end

  test "投稿が必須であること" do
    bookmark = Bookmark.new(user: @user, post: nil)
    assert_not bookmark.valid?
    assert_includes bookmark.errors[:post], "must exist"
  end

  test "同じユーザーは同じ投稿を重複ブックマークできないこと" do
    Bookmark.where(user: @user, post: @post).destroy_all
    Bookmark.create!(user: @user, post: @post)

    duplicate = Bookmark.new(user: @user, post: @post)
    assert_not duplicate.valid?
    assert duplicate.errors[:user_id].present?, "Expected duplicate bookmark to have a uniqueness error"
  end

  test "異なるユーザーは同じ投稿をブックマークできること" do
    Bookmark.where(user: [ @user, @another_user ], post: @post).destroy_all

    Bookmark.create!(user: @user, post: @post)
    other_users_bookmark = Bookmark.new(user: @another_user, post: @post)

    assert other_users_bookmark.valid?, "Expected bookmark to be valid but had errors: #{other_users_bookmark.errors.full_messages}"
  end

  test "同じユーザーが異なる投稿をブックマークできること" do
    another_post = posts(:another_post)

    Bookmark.where(user: @user, post: @post).destroy_all
    Bookmark.create!(user: @user, post: @post)

    bookmark = Bookmark.new(user: @user, post: another_post)
    assert bookmark.valid?, "Expected bookmark to be valid but had errors: #{bookmark.errors.full_messages}"
  end
end
