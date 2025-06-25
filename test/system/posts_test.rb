require "application_system_test_case"

class PostsTest < ApplicationSystemTestCase
  def setup
    @user = users(:test_user)
    @category = categories(:general)
  end

  test "投稿一覧ページを表示できること" do
    visit posts_url
    assert_selector "h1", text: "投稿一覧"
  end

  test "ログイン時に投稿を作成できること" do
    # ログイン
    login_as(@user)

    # 投稿作成ページに移動
    visit posts_url
    click_on "新規投稿"

    # ページが読み込まれるまで待つ
    assert_selector "form", wait: 10

    # フォームに入力（Stale Element Referenceを避けるため、毎回要素を探す）
    fill_in "post[title]", with: "Test Post Title"
    fill_in "post[content]", with: "Test post content"
    select @category.name, from: "post[category_id]"

    # 投稿ボタンをクリック
    click_button "投稿"

    # 結果を確認（投稿が作成されたことを確認）
    assert_text "Test Post Title"
    assert_text "投稿が作成されました"
  end
end