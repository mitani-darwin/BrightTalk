require "application_system_test_case"

class FormUITest < ApplicationSystemTestCase
  include Devise::Test::IntegrationHelpers

  def setup
    @user = users(:test_user)
    @category = categories(:general)
    @post_type = post_types(:tutorial)
  end

  test "投稿ボタンとキャンセルボタンが内容欄に2列で表示されること" do
    sign_in @user
    visit new_post_path
    
    # Wait for form to load
    assert_selector "form", wait: 10
    
    # Check that submit buttons are in the main content area (right side)
    within ".col-md-8" do
      assert_selector ".row .col-6", count: 2, text: "投稿"
      assert_selector ".row .col-6", text: "キャンセル"
      
      # Verify buttons are full width within their columns
      assert_selector ".btn.w-100", text: "投稿"
      assert_selector ".btn.w-100", text: "キャンセル"
    end
  end

  test "画像ファイル選択時にマークダウンリンクが挿入されること" do
    sign_in @user
    visit new_post_path
    
    # Wait for form and JavaScript to load
    assert_selector "#contentTextarea", wait: 10
    sleep 2
    
    # Fill basic form fields first
    fill_in "post[title]", with: "画像挿入テスト"
    
    # Set initial cursor position in textarea
    page.execute_script("document.getElementById('contentTextarea').focus();")
    page.execute_script("document.getElementById('contentTextarea').setSelectionRange(0, 0);")
    
    # Simulate image file selection
    attach_file "post[images][]", Rails.root.join("test", "fixtures", "files", "test_image.jpg")
    
    # Wait for JavaScript to process the file
    sleep 1
    
    # Check that Markdown link was inserted
    content_value = page.evaluate_script("document.getElementById('contentTextarea').value")
    assert_includes content_value, "![test_image.jpg](attachment:test_image.jpg)"
  end

  test "動画ファイル選択時にマークダウンリンクが挿入されること" do
    sign_in @user
    visit new_post_path
    
    # Wait for form and JavaScript to load
    assert_selector "#contentTextarea", wait: 10
    sleep 2
    
    # Fill basic form fields first
    fill_in "post[title]", with: "動画挿入テスト"
    
    # Set initial cursor position in textarea
    page.execute_script("document.getElementById('contentTextarea').focus();")
    page.execute_script("document.getElementById('contentTextarea').setSelectionRange(0, 0);")
    
    # Simulate video file selection
    attach_file "videoInput", Rails.root.join("test", "fixtures", "files", "test_video.mp4")
    
    # Wait for JavaScript to process the file
    sleep 1
    
    # Check that Markdown link was inserted
    content_value = page.evaluate_script("document.getElementById('contentTextarea').value")
    assert_includes content_value, "[test_video.mp4](attachment:test_video.mp4)"
  end

  test "既存画像の挿入ボタンが動作すること" do
    # Create post with existing image
    post_with_image = Post.create!(
      title: "既存画像テスト",
      content: "既存画像のテスト",
      purpose: "テスト目的",
      target_audience: "テストユーザー",
      user: @user,
      category: @category,
      post_type: @post_type,
      status: :published
    )

    post_with_image.images.attach(
      io: File.open(Rails.root.join("test", "fixtures", "files", "test_image.jpg")),
      filename: "existing_image.jpg",
      content_type: "image/jpeg"
    )

    sign_in @user
    visit edit_post_path(post_with_image)
    
    # Wait for form to load
    assert_selector "#contentTextarea", wait: 10
    assert_selector ".insert-existing-image", wait: 10
    
    # Clear textarea content first
    page.execute_script("document.getElementById('contentTextarea').value = '';")
    page.execute_script("document.getElementById('contentTextarea').focus();")
    
    # Click insert button
    find(".insert-existing-image").click
    
    # Wait for insertion
    sleep 1
    
    # Check that image was inserted into textarea
    content_value = page.evaluate_script("document.getElementById('contentTextarea').value")
    assert_includes content_value, "![existing_image.jpg](attachment:existing_image.jpg)"
    
    # Check for success message
    assert_selector "#dynamicAlerts .alert-success", wait: 5
  end

  test "既存動画の挿入ボタンが動作すること" do
    # Create post with existing video
    post_with_video = Post.create!(
      title: "既存動画テスト",
      content: "既存動画のテスト",
      purpose: "テスト目的",
      target_audience: "テストユーザー",
      user: @user,
      category: @category,
      post_type: @post_type,
      status: :published
    )

    post_with_video.videos.attach(
      io: File.open(Rails.root.join("test", "fixtures", "files", "test_video.mp4")),
      filename: "existing_video.mp4",
      content_type: "video/mp4"
    )

    sign_in @user
    visit edit_post_path(post_with_video)
    
    # Wait for form to load
    assert_selector "#contentTextarea", wait: 10
    assert_selector ".insert-existing-video", wait: 10
    
    # Clear textarea content first
    page.execute_script("document.getElementById('contentTextarea').value = '';")
    page.execute_script("document.getElementById('contentTextarea').focus();")
    
    # Click insert button
    find(".insert-existing-video").click
    
    # Wait for insertion
    sleep 1
    
    # Check that video was inserted into textarea
    content_value = page.evaluate_script("document.getElementById('contentTextarea').value")
    assert_includes content_value, "[existing_video.mp4](attachment:existing_video.mp4)"
    
    # Check for success message
    assert_selector "#dynamicAlerts .alert-success", wait: 5
  end

  test "画像削除ボタンが動作すること" do
    # Create post with existing image
    post_with_image = Post.create!(
      title: "画像削除テスト",
      content: "画像削除のテスト",
      purpose: "テスト目的",
      target_audience: "テストユーザー",
      user: @user,
      category: @category,
      post_type: @post_type,
      status: :published
    )

    post_with_image.images.attach(
      io: File.open(Rails.root.join("test", "fixtures", "files", "test_image.jpg")),
      filename: "delete_test_image.jpg",
      content_type: "image/jpeg"
    )

    attachment_id = post_with_image.images.first.id

    sign_in @user
    visit edit_post_path(post_with_image)
    
    # Wait for form to load
    assert_selector ".delete-image-btn", wait: 10
    
    # Mock the confirmation dialog to always return true
    page.execute_script("window.confirm = function() { return true; }")
    
    # Click delete button
    find(".delete-image-btn").click
    
    # Wait for deletion to complete
    sleep 2
    
    # Check that image card was removed from DOM
    assert_no_selector "#image-card-#{attachment_id}", wait: 10
    
    # Check for success message
    assert_selector "#dynamicAlerts .alert-success", wait: 5
  end

  test "動画削除ボタンが動作すること" do
    # Create post with existing video
    post_with_video = Post.create!(
      title: "動画削除テスト",
      content: "動画削除のテスト",
      purpose: "テスト目的",
      target_audience: "テストユーザー",
      user: @user,
      category: @category,
      post_type: @post_type,
      status: :published
    )

    post_with_video.videos.attach(
      io: File.open(Rails.root.join("test", "fixtures", "files", "test_video.mp4")),
      filename: "delete_test_video.mp4",
      content_type: "video/mp4"
    )

    attachment_id = post_with_video.videos.first.id

    sign_in @user
    visit edit_post_path(post_with_video)
    
    # Wait for form to load
    assert_selector ".delete-video-btn", wait: 10
    
    # Mock the confirmation dialog to always return true
    page.execute_script("window.confirm = function() { return true; }")
    
    # Click delete button
    find(".delete-video-btn").click
    
    # Wait for deletion to complete
    sleep 2
    
    # Check that video card was removed from DOM
    assert_no_selector "#video-card-#{attachment_id}", wait: 10
    
    # Check for success message
    assert_selector "#dynamicAlerts .alert-success", wait: 5
  end

  test "マークダウンリンク挿入がカーソル位置で動作すること" do
    sign_in @user
    visit new_post_path
    
    # Wait for form and JavaScript to load
    assert_selector "#contentTextarea", wait: 10
    sleep 2
    
    # Set some initial content
    page.execute_script("document.getElementById('contentTextarea').value = 'Before\\n\\nAfter';")
    
    # Set cursor position in the middle (after "Before\n\n")
    page.execute_script("document.getElementById('contentTextarea').setSelectionRange(8, 8);")
    page.execute_script("document.getElementById('contentTextarea').focus();")
    
    # Simulate image file selection
    attach_file "post[images][]", Rails.root.join("test", "fixtures", "files", "test_image.jpg")
    
    # Wait for JavaScript to process
    sleep 1
    
    # Check that markdown was inserted at the correct position
    content_value = page.evaluate_script("document.getElementById('contentTextarea').value")
    expected_content = "Before\n\n![test_image.jpg](attachment:test_image.jpg)\n\nAfter"
    assert_equal expected_content, content_value
  end
end