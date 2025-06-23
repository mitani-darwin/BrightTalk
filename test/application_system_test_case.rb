require "application_system_test_case"

class PostsTest < ApplicationSystemTestCase
  def setup
    @user = users(:test_user)
    @category = categories(:general)
  end

  test "visiting the index" do
    visit posts_url
    assert_selector "h1", text: "投稿一覧"
  end

  test "should create post when signed in" do
    # ログイン
    visit new_user_session_url
    fill_in "Email", with: @user.email
    fill_in "Password", with: "Password123!"
    click_on "ログイン"

    # 投稿作成
    click_on "新規投稿"
    fill_in "Title", with: "Test Post Title"
    fill_in "Content", with: "Test post content"
    select @category.name, from: "Category"
    click_on "投稿する"

    assert_text "投稿が作成されました"
    assert_text "Test Post Title"
  end
end