require "application_system_test_case"

class PostsTest < ApplicationSystemTestCase
  include Devise::Test::IntegrationHelpers

  def setup
    @user = users(:test_user)
    @category = categories(:general)
  end

  test "投稿一覧ページを表示できること" do
    visit posts_url
    assert_selector "h1", text: "投稿一覧"
  end

  test "ログイン時に投稿を作成できること（Deviseヘルパー使用）" do
    # Deviseヘルパーを使用してログイン（より確実）
    sign_in @user

    # 投稿作成ページに移動
    visit posts_url
    puts "Current URL after login: #{current_url}"

    # 新規投稿リンクの存在確認とクリック
    puts "Available links on posts page:"
    page.all("a").each { |link| puts "- #{link.text}: #{link[:href]}" }

    if page.has_link?("新規投稿")
      click_on "新規投稿"
    elsif page.has_link?("New Post")
      click_on "New Post"
    elsif page.has_link?("投稿作成")
      click_on "投稿作成"
    else
      # 直接新規投稿ページに移動
      puts "No new post link found, visiting new_post_path directly"
      visit new_post_path
    end

    # 現在のページ情報を出力
    puts "Current URL after navigation: #{current_url}"
    puts "Page contains form: #{page.has_css?('form')}"

    # フォームの存在確認とフィールド調査
    assert_selector "form", wait: 10

    # 利用可能なフィールドを確認
    puts "Available form fields:"
    page.all("input, textarea, select").each do |field|
      puts "- #{field.tag_name}: name=#{field[:name]}, id=#{field[:id]}, type=#{field[:type]}"
    end

    # タイトルフィールドを複数パターンで試行
    title_filled = false
    [ "post[title]", "post_title", "title" ].each do |field_name|
      if page.has_field?(field_name)
        fill_in field_name, with: "Test Post Title"
        title_filled = true
        puts "Filled title field: #{field_name}"
        break
      end
    end

    unless title_filled
      # CSSセレクタで直接検索
      if page.has_css?("input[name*='title']")
        page.find("input[name*='title']").set("Test Post Title")
        title_filled = true
        puts "Filled title field using CSS selector"
      end
    end

    assert title_filled, "Could not find or fill title field"

    # コンテンツフィールドを複数パターンで試行
    content_filled = false
    [ "post[content]", "post_content", "content" ].each do |field_name|
      if page.has_field?(field_name)
        fill_in field_name, with: "Test post content"
        content_filled = true
        puts "Filled content field: #{field_name}"
        break
      end
    end

    unless content_filled
      # CSSセレクタで直接検索
      if page.has_css?("textarea[name*='content']")
        page.find("textarea[name*='content']").set("Test post content")
        content_filled = true
        puts "Filled content field using CSS selector"
      end
    end

    assert content_filled, "Could not find or fill content field"

    # 投稿目的フィールドを埋める
    purpose_filled = false
    if page.has_field?("post[purpose]")
      fill_in "post[purpose]", with: "System test purpose"
      purpose_filled = true
      puts "Filled purpose field"
    elsif page.has_css?("textarea[name*='purpose']")
      page.find("textarea[name*='purpose']").set("System test purpose")
      purpose_filled = true
      puts "Filled purpose field using CSS selector"
    end
    assert purpose_filled, "Could not find or fill purpose field"

    # 対象読者フィールドを埋める
    target_audience_filled = false
    if page.has_field?("post[target_audience]")
      fill_in "post[target_audience]", with: "System test audience"
      target_audience_filled = true
      puts "Filled target_audience field"
    elsif page.has_css?("input[name*='target_audience']")
      page.find("input[name*='target_audience']").set("System test audience")
      target_audience_filled = true
      puts "Filled target_audience field using CSS selector"
    end
    assert target_audience_filled, "Could not find or fill target_audience field"

    # 投稿タイプ選択
    post_type_selected = false
    if page.has_select?("post[post_type_id]")
      # 最初のオプション（プロンプト以外）を選択
      options = page.find("select[name='post[post_type_id]']").all("option")
      if options.length > 1
        select options[1].text, from: "post[post_type_id]"
        post_type_selected = true
        puts "Selected post type: #{options[1].text}"
      end
    elsif page.has_css?("select[name*='post_type']")
      select_element = page.find("select[name*='post_type']")
      options = select_element.all("option")
      if options.length > 1
        select_element.select(options[1].text)
        post_type_selected = true
        puts "Selected post type using CSS selector"
      end
    end
    assert post_type_selected, "Could not find or select post type"

    # カテゴリ選択（存在する場合）
    if page.has_select?("post[category_id]")
      select @category.name, from: "post[category_id]"
      puts "Selected category: #{@category.name}"
    elsif page.has_css?("select[name*='category']")
      page.find("select[name*='category']").select(@category.name)
      puts "Selected category using CSS selector"
    else
      puts "No category select field found"
    end

    # 投稿ボタンをクリック
    submit_clicked = false
    [ "投稿", "Create Post", "Submit", "作成" ].each do |button_text|
      if page.has_button?(button_text)
        click_button button_text
        submit_clicked = true
        puts "Clicked button: #{button_text}"
        break
      end
    end

    unless submit_clicked
      # type=submitのボタンを探す
      if page.has_css?("input[type='submit']")
        page.find("input[type='submit']").click
        submit_clicked = true
        puts "Clicked submit button using CSS selector"
      end
    end

    assert submit_clicked, "Could not find or click submit button"

    # 結果を確認（投稿が作成されたことを確認）
    puts "Final URL: #{current_url}"
    puts "Page content includes 'Test Post Title': #{page.has_content?('Test Post Title')}"

    # 成功メッセージまたは投稿タイトルの存在を確認
    success_confirmed = false

    if page.has_content?("Test Post Title")
      success_confirmed = true
      puts "Found post title on page"
    end

    success_messages = [ "投稿が作成されました", "Post was successfully created", "作成しました" ]
    success_messages.each do |message|
      if page.has_content?(message)
        success_confirmed = true
        puts "Found success message: #{message}"
        break
      end
    end

    assert success_confirmed, "Post creation was not confirmed"
  end

  test "手動ログイン時に投稿を作成できること" do
    # 手動ログインを試行
    login_as(@user)

    # 以下は上記と同様のロジック
    visit posts_url

    if page.has_link?("新規投稿")
      click_on "新規投稿"
    else
      visit new_post_path
    end

    assert_selector "form", wait: 10

    fill_in "post[title]", with: "Manual Login Test Post"
    fill_in "post[content]", with: "Manual login test content"
    fill_in "post[purpose]", with: "Manual test purpose"
    fill_in "post[target_audience]", with: "Manual test audience"

    # 投稿タイプ選択
    if page.has_select?("post[post_type_id]")
      options = page.find("select[name='post[post_type_id]']").all("option")
      if options.length > 1
        select options[1].text, from: "post[post_type_id]"
      end
    end

    if page.has_select?("post[category_id]")
      select @category.name, from: "post[category_id]"
    end

    click_button "投稿"

    assert_text "Manual Login Test Post"
  end
end
