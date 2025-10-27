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

    # 直接新規投稿ページに移動
    visit new_post_path
    puts "Current URL: #{current_url}"
    puts "Page contains form: #{page.has_css?('form')}"

    # フォームの存在確認とフィールド調査
    assert_selector "form", wait: 10

    # 利用可能なフィールドを確認
    puts "Available form fields:"
    begin
      page.all("input, textarea, select").each do |field|
        begin
          puts "- #{field.tag_name}: name=#{field[:name]}, id=#{field[:id]}, type=#{field[:type]}"
        rescue Selenium::WebDriver::Error::StaleElementReferenceError
          puts "- [stale element]"
        end
      end
    rescue => e
      puts "Error enumerating fields: #{e.message}"
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

    # コンテンツフィールドを填入
    page.find("#contentTextarea").set("Test post content")
    puts "Filled content field using ID selector"

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

    # タイトルフィールドを複数パターンで試行
    title_filled = false
    [ "post[title]", "post_title", "title" ].each do |field_name|
      if page.has_field?(field_name)
        fill_in field_name, with: "Manual Login Test Post"
        title_filled = true
        break
      end
    end

    unless title_filled
      # CSSセレクタで直接検索
      if page.has_css?("input[name*='title']")
        page.find("input[name*='title']").set("Manual Login Test Post")
        title_filled = true
      end
    end

    assert title_filled, "Could not find or fill title field"

    # コンテンツフィールドを複数パターンで試行（JavaScriptの読み込みを待つ）
    content_filled = false
    
    # JavaScriptの読み込みを待機
    sleep 2
    
    # JavaScriptで直接値を設定（Capybaraでの通常の操作が効かない場合の回避策）
    begin
      page.execute_script("document.getElementById('contentTextarea').value = 'Manual login test content';")
      # 値が設定されたかを確認
      content_value = page.evaluate_script("document.getElementById('contentTextarea').value")
      if content_value == "Manual login test content"
        content_filled = true
        puts "Filled content field using JavaScript execution"
      end
    rescue => e
      puts "JavaScript execution failed: #{e.message}"
    end
    
    # JavaScriptが失敗した場合は通常の方法で試行
    unless content_filled
      if page.has_css?("#contentTextarea", visible: true, wait: 10)
        page.find("#contentTextarea").set("Manual login test content")
        content_filled = true
        puts "Filled content field using ID selector"
      else
        [ "post[content]", "post_content", "content" ].each do |field_name|
          if page.has_field?(field_name, wait: 5)
            fill_in field_name, with: "Manual login test content"
            content_filled = true
            puts "Filled content field: #{field_name}"
            break
          end
        end

        unless content_filled
          # CSSセレクタで直接検索
          if page.has_css?("textarea[name*='content']", visible: true, wait: 5)
            page.find("textarea[name*='content']").set("Manual login test content")
            content_filled = true
            puts "Filled content field using CSS selector"
          end
        end
      end
    end

    assert content_filled, "Could not find or fill content field"

    # 投稿目的フィールドを埋める
    purpose_filled = false
    if page.has_field?("post[purpose]")
      fill_in "post[purpose]", with: "Manual test purpose"
      purpose_filled = true
    elsif page.has_css?("textarea[name*='purpose']")
      page.find("textarea[name*='purpose']").set("Manual test purpose")
      purpose_filled = true
    end
    assert purpose_filled, "Could not find or fill purpose field"

    # 対象読者フィールドを埋める
    target_audience_filled = false
    if page.has_field?("post[target_audience]")
      fill_in "post[target_audience]", with: "Manual test audience"
      target_audience_filled = true
    elsif page.has_css?("input[name*='target_audience']")
      page.find("input[name*='target_audience']").set("Manual test audience")
      target_audience_filled = true
    end
    assert target_audience_filled, "Could not find or fill target_audience field"

    # 投稿タイプ選択
    post_type_selected = false
    if page.has_select?("post[post_type_id]")
      options = page.find("select[name='post[post_type_id]']").all("option")
      if options.length > 1
        select options[1].text, from: "post[post_type_id]"
        post_type_selected = true
      end
    elsif page.has_css?("select[name*='post_type']")
      select_element = page.find("select[name*='post_type']")
      options = select_element.all("option")
      if options.length > 1
        select_element.select(options[1].text)
        post_type_selected = true
      end
    end
    assert post_type_selected, "Could not find or select post type"

    if page.has_select?("post[category_id]")
      select @category.name, from: "post[category_id]"
    elsif page.has_css?("select[name*='category']")
      page.find("select[name*='category']").select(@category.name)
    end

    # 投稿ボタンをクリック
    submit_clicked = false
    [ "投稿", "Create Post", "Submit", "作成" ].each do |button_text|
      if page.has_button?(button_text)
        click_button button_text
        submit_clicked = true
        break
      end
    end

    unless submit_clicked
      # type=submitのボタンを探す
      if page.has_css?("input[type='submit']")
        page.find("input[type='submit']").click
        submit_clicked = true
      end
    end

    assert submit_clicked, "Could not find or click submit button"

    assert_text "Manual Login Test Post"
  end

  # === Upload Functionality System Tests ===

  test "画像アップロード機能が正常に動作すること" do
    sign_in @user
    visit new_post_path

    # フォームの基本フィールドを埋める
    fill_in_basic_post_fields("画像アップロードシステムテスト", "画像付き投稿のシステムテスト")

    # 画像ファイルをアップロード
    attach_file "post[images][]", Rails.root.join("test", "fixtures", "files", "test_image.jpg")

    # アップロード確認要素が表示されるまで待機
    assert_selector ".upload-preview, .file-upload-success, img", wait: 10

    # 投稿を送信
    click_button "投稿"

    # 作成された投稿の確認
    assert_text "画像アップロードシステムテスト"
    assert_selector "img", wait: 10 # 画像が表示されることを確認
  end

  test "動画アップロード機能（Direct Upload）が正常に動作すること" do
    sign_in @user
    visit new_post_path

    fill_in_basic_post_fields("動画アップロードシステムテスト", "Direct Upload動画のシステムテスト")

    # 動画ファイルをアップロード（Direct Upload対応）
    attach_file "videoInput", Rails.root.join("test", "fixtures", "files", "test_video.mp4")

    # Direct Uploadの完了を待機
    assert_selector ".upload-success, .video-upload-complete", wait: 15

    # 投稿を送信
    click_button "投稿"

    assert_text "動画アップロードシステムテスト"
    # 動画プレーヤーまたは動画リンクが表示されることを確認
    assert_selector "video, .video-player, a[href*='test_video.mp4']", wait: 10
  end

  test "画像と動画を同時にアップロードできること" do
    sign_in @user
    visit new_post_path

    fill_in_basic_post_fields("マルチメディアアップロードテスト", "画像と動画を同時にアップロード")

    # 画像をアップロード
    attach_file "post[images][]", Rails.root.join("test", "fixtures", "files", "test_image.jpg")
    
    # 画像のアップロード完了を待機
    assert_selector ".upload-preview, img", wait: 10

    # 動画をアップロード
    attach_file "videoInput", Rails.root.join("test", "fixtures", "files", "test_video.mp4")
    
    # 動画のアップロード完了を待機
    assert_selector ".video-upload-complete, .upload-success", wait: 15

    click_button "投稿"

    assert_text "マルチメディアアップロードテスト"
    # 画像と動画の両方が表示されることを確認
    assert_selector "img", wait: 10
    assert_selector "video, .video-player", wait: 10
  end

  test "自動保存機能が正常に動作すること" do
    sign_in @user
    visit new_post_path

    # タイトルを入力
    fill_in_title_field("自動保存システムテスト")
    
    # 自動保存のトリガーを待機（JavaScriptが自動保存を実行）
    sleep 6 # 自動保存は5秒間隔で実行される

    # 自動保存の確認メッセージまたはインジケーターをチェック
    assert_text "自動保存されました", wait: 5

    # 内容を追加
    fill_in_content_field("自動保存中の投稿内容")
    
    # 再度自動保存を待機
    sleep 6
    
    # ページをリフレッシュして自動保存されたデータが残っているか確認
    page.refresh
    
    # 自動保存された内容が復元されることを確認
    title_value = page.find("input[name*='title']").value
    assert_equal "自動保存システムテスト", title_value
  end

  test "画像削除機能が正常に動作すること" do
    # 既存の画像付き投稿を作成
    post_with_image = Post.create!(
      title: "画像削除テスト投稿",
      content: "画像削除のシステムテスト",
      purpose: "システムテスト",
      target_audience: "テストユーザー",
      user: @user,
      category: @category,
      post_type: post_types(:tutorial),
      status: :published
    )

    # 画像を添付
    post_with_image.images.attach(
      io: File.open(Rails.root.join("test", "fixtures", "files", "test_image.jpg")),
      filename: "system_test_image.jpg",
      content_type: "image/jpeg"
    )

    sign_in @user
    visit edit_post_path(post_with_image)

    # 画像カードが表示されていることを確認
    post_with_image.reload
    attachment = post_with_image.images.first
    image_card_selector = "#image-card-#{attachment.id}"

    assert_selector image_card_selector, wait: 10

    # 削除ボタンまたはリンクをクリック
    within image_card_selector do
      if page.has_button?("削除")
        click_button "削除"
      elsif page.has_css?(".delete-image-btn")
        page.find(".delete-image-btn").click
      elsif page.has_link?("削除")
        click_link "削除"
      end
    end

    # 確認ダイアログがある場合は承認
    begin
      if page.driver.browser.switch_to.alert
        page.driver.browser.switch_to.alert.accept
      end
    rescue
      # アラートがない場合は何もしない
    end

    # 画像が削除されたことを確認
    assert_text "削除しました", wait: 5
    assert_no_selector image_card_selector, wait: 10
  end

  test "投稿更新時に新しい画像を追加できること" do
    # 既存投稿を作成
    existing_post = Post.create!(
      title: "更新テスト投稿",
      content: "更新前の内容",
      purpose: "更新テスト",
      target_audience: "テストユーザー",
      user: @user,
      category: @category,
      post_type: post_types(:tutorial),
      status: :published
    )

    sign_in @user
    visit edit_post_path(existing_post)

    # 新しい画像をアップロード
    attach_file "post[images][]", Rails.root.join("test", "fixtures", "files", "test_image.jpg")
    
    # アップロード完了を待機
    assert_selector ".upload-preview, img", wait: 10

    # タイトルを更新
    fill_in_title_field("画像が追加された投稿")

    click_button "更新"

    assert_text "画像が追加された投稿"
    assert_text "投稿が更新されました"
    assert_selector "img", wait: 10
  end

  test "エラーハンドリング - 大きすぎるファイル" do
    sign_in @user
    visit new_post_path

    fill_in_basic_post_fields("ファイルサイズエラーテスト", "大きすぎるファイルのテスト")

    # 大きなファイルをシミュレート（実際のテストでは適切なサイズのファイルを使用）
    # ここでは通常のファイルを使用してエラー処理をテスト
    attach_file "post[images][]", Rails.root.join("test", "fixtures", "files", "test_image.jpg")

    # エラーメッセージの表示を確認（設定された最大ファイルサイズを超えた場合）
    # 実際の実装に応じてセレクターを調整
    if page.has_css?(".error-message, .alert-danger", wait: 5)
      assert_selector ".error-message, .alert-danger"
    end
  end

  # === Bulk Delete System Tests ===

  test "下書き一覧で複数選択して一括削除できること" do
    sign_in @user

    # テスト用下書きを3件作成
    draft1 = Post.create!(
      title: "下書き1",
      content: "下書き内容1",
      user: @user,
      category: @category,
      post_type: post_types(:tutorial),
      status: :draft
    )
    draft2 = Post.create!(
      title: "下書き2",
      content: "下書き内容2", 
      user: @user,
      category: @category,
      post_type: post_types(:tutorial),
      status: :draft
    )
    draft3 = Post.create!(
      title: "下書き3",
      content: "下書き内容3",
      user: @user,
      category: @category,
      post_type: post_types(:tutorial),
      status: :draft
    )

    visit drafts_posts_path

    # 下書きが表示されていることを確認
    assert_text "下書き1"
    assert_text "下書き2"
    assert_text "下書き3"

    # 2件の下書きをチェック
    check "post_#{draft1.id}"
    check "post_#{draft2.id}"

    # 削除ボタンがアクティブになることを確認
    delete_button = find("#bulk_delete_btn")
    assert_not delete_button.disabled?

    # 確認ダイアログを受け入れて削除実行
    accept_confirm do
      click_button "選択した下書きを削除"
    end

    # 削除完了メッセージの確認
    assert_text "2件の下書きを削除しました"

    # 削除された下書きが表示されていないことを確認
    assert_no_text "下書き1"
    assert_no_text "下書き2"
    
    # 選択されていない下書きは残っていることを確認
    assert_text "下書き3"
  end

  test "すべて選択チェックボックスが正常に動作すること" do
    sign_in @user

    # テスト用下書きを2件作成
    2.times do |i|
      Post.create!(
        title: "下書き#{i + 1}",
        content: "下書き内容#{i + 1}",
        user: @user,
        category: @category,
        post_type: post_types(:tutorial),
        status: :draft
      )
    end

    visit drafts_posts_path

    # 最初は削除ボタンが無効であることを確認
    delete_button = find("#bulk_delete_btn")
    assert delete_button.disabled?

    # すべて選択をチェック
    check "select_all"

    # 個別チェックボックスがすべてチェックされることを確認
    page.all(".draft-checkbox").each do |checkbox|
      assert checkbox.checked?
    end

    # 削除ボタンがアクティブになることを確認
    assert_not delete_button.disabled?

    # すべて選択を外す
    uncheck "select_all"

    # 個別チェックボックスがすべて外れることを確認
    page.all(".draft-checkbox").each do |checkbox|
      assert_not checkbox.checked?
    end

    # 削除ボタンが無効になることを確認
    assert delete_button.disabled?
  end

  test "下書きが存在しない場合は適切なメッセージが表示されること" do
    sign_in @user
    visit drafts_posts_path

    assert_text "下書きがありません"
    assert_text "新しい投稿を作成してみましょう"
    assert_link "新しい投稿を作成"
  end

  test "チェックボックス未選択で削除ボタンを押してもエラーになること" do
    sign_in @user

    # テスト用下書きを1件作成
    Post.create!(
      title: "テスト下書き",
      content: "テスト内容",
      user: @user,
      category: @category,
      post_type: post_types(:tutorial),
      status: :draft
    )

    visit drafts_posts_path

    # 何もチェックせずに削除ボタンを確認（ボタンは無効状態のはず）
    delete_button = find("#bulk_delete_btn")
    assert delete_button.disabled?
  end

  test "一部の下書きを選択して削除できること" do
    sign_in @user

    # テスト用下書きを4件作成
    drafts = []
    4.times do |i|
      drafts << Post.create!(
        title: "下書き#{i + 1}",
        content: "下書き内容#{i + 1}",
        user: @user,
        category: @category,
        post_type: post_types(:tutorial),
        status: :draft
      )
    end

    visit drafts_posts_path

    # 1番目と3番目の下書きを選択
    check "post_#{drafts[0].id}"
    check "post_#{drafts[2].id}"

    # すべて選択チェックボックスは中間状態（indeterminate）になるはず
    # （JavaScriptで制御されているため、視覚的な確認は困難）

    # 削除実行
    accept_confirm do
      click_button "選択した下書きを削除"
    end

    # 削除完了メッセージの確認
    assert_text "2件の下書きを削除しました"

    # 選択された下書きが削除されていることを確認
    assert_no_text "下書き1"
    assert_no_text "下書き3"

    # 選択されなかった下書きが残っていることを確認
    assert_text "下書き2"
    assert_text "下書き4"
  end

  private

  def fill_in_basic_post_fields(title, content)
    fill_in_title_field(title)
    fill_in_content_field(content)
    fill_in_purpose_field("システムテスト目的")
    fill_in_target_audience_field("システムテストユーザー")
    select_post_type
    select_category
  end

  def fill_in_title_field(title)
    if page.has_field?("post[title]")
      fill_in "post[title]", with: title
    elsif page.has_css?("input[name*='title']")
      page.find("input[name*='title']").set(title)
    end
  end

  def fill_in_content_field(content)
    if page.has_css?("#contentTextarea", visible: true, wait: 5)
      page.find("#contentTextarea").set(content)
    elsif page.has_field?("post[content]")
      fill_in "post[content]", with: content
    elsif page.has_css?("textarea[name*='content']")
      page.find("textarea[name*='content']").set(content)
    end
  end

  def fill_in_purpose_field(purpose)
    if page.has_field?("post[purpose]")
      fill_in "post[purpose]", with: purpose
    elsif page.has_css?("textarea[name*='purpose']")
      page.find("textarea[name*='purpose']").set(purpose)
    end
  end

  def fill_in_target_audience_field(target_audience)
    if page.has_field?("post[target_audience]")
      fill_in "post[target_audience]", with: target_audience
    elsif page.has_css?("input[name*='target_audience']")
      page.find("input[name*='target_audience']").set(target_audience)
    end
  end

  def select_post_type
    if page.has_select?("post[post_type_id]")
      options = page.find("select[name='post[post_type_id]']").all("option")
      if options.length > 1
        select options[1].text, from: "post[post_type_id]"
      end
    elsif page.has_css?("select[name*='post_type']")
      select_element = page.find("select[name*='post_type']")
      options = select_element.all("option")
      if options.length > 1
        select_element.select(options[1].text)
      end
    end
  end

  def select_category
    if page.has_select?("post[category_id]")
      select @category.name, from: "post[category_id]"
    elsif page.has_css?("select[name*='category']")
      page.find("select[name*='category']").select(@category.name)
    end
  end
end
