require "application_system_test_case"

class UserPostsNavigationTest < ApplicationSystemTestCase
  def setup
    @user = users(:test_user)
    @other_user = users(:another_user)
    @user_post = posts(:first_post)
    @other_post = posts(:another_post)
  end

  test "投稿一覧からユーザー別投稿一覧に遷移できること" do
    visit posts_path

    assert_text @user.name
    click_link @user.name

    assert_current_path user_posts_path(@user), ignore_query: true
    assert_text "#{@user.name}さんの投稿一覧"
    assert_text @user_post.title
    assert_no_text @other_post.title
  end
end
