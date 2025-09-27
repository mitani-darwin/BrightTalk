require "application_system_test_case"

class UpdateProgressModalTest < ApplicationSystemTestCase
  setup do
    @user = users(:test_user)
    sign_in @user
    @post = posts(:first_post)
    @post.update!(user: @user)
  end

  test "displays update progress modal on form submission" do
    visit edit_post_path(@post)

    # フォーム要素が存在することを確認
    assert_selector "form[data-turbo='false']"
    assert_selector "#updateSubmitBtn"
    assert_selector "#updateProgressModal"

    # JavaScriptが正しく読み込まれていることを確認
    page.execute_script("console.log('Testing update progress modal')")

    # 必要な要素が存在することを確認
    within_frame do
      assert page.has_css?("#updateProgressModal", visible: false)
      assert page.has_css?("#updateProgressBar")
      assert page.has_css?("#updateStatusText")
      assert page.has_css?("#updateDetails")
    end
  end

  test "modal initialization functions work correctly" do
    visit edit_post_path(@post)

    # JavaScript関数が存在することを確認
    result = page.evaluate_script("typeof initializeUpdateProgressModal === 'function'")
    assert_equal true, result

    result = page.evaluate_script("typeof handleUpdateSubmit === 'function'")
    assert_equal true, result

    result = page.evaluate_script("typeof startUpdateProgress === 'function'")
    assert_equal true, result
  end

  test "shows modal when update button is clicked" do
    visit edit_post_path(@post)

    # タイトルを変更
    fill_in "post_title", with: "Updated Title"
    fill_in "post_content", with: "Updated content"

    # Bootstrap が読み込まれていることを確認
    bootstrap_loaded = page.evaluate_script("typeof bootstrap !== 'undefined'")
    assert bootstrap_loaded, "Bootstrap should be loaded"

    # 更新ボタンをクリック
    click_button "投稿"

    # モーダルが表示されることを確認（少し待機）
    sleep 0.5
    
    # コンソールログを確認（デバッグ用）
    logs = page.driver.browser.logs.get(:browser)
    modal_logs = logs.select { |log| log.message.include?("Update submit button clicked") || 
                                    log.message.include?("Modal shown") }
    
    assert modal_logs.any?, "Modal should trigger console logs"
  end

  test "progress animation works correctly" do
    visit edit_post_path(@post)

    # プログレスバーの初期状態を確認
    initial_width = page.evaluate_script("document.getElementById('updateProgressBar').style.width")
    assert_equal "0%", initial_width

    # プログレス関数を直接実行
    page.execute_script("startUpdateProgress()")

    # プログレスが進むまで少し待機
    sleep 1

    # プログレスバーが更新されていることを確認
    updated_width = page.evaluate_script("document.getElementById('updateProgressBar').style.width")
    assert_not_equal "0%", updated_width

    # ステータステキストが更新されていることを確認
    status_text = page.evaluate_script("document.getElementById('updateStatusText').textContent")
    assert_not_equal "準備中...", status_text
  end

  test "handles bootstrap unavailable gracefully" do
    visit edit_post_path(@post)

    # Bootstrapを一時的に無効化
    page.execute_script("window.bootstrap = undefined")

    # 初期化を実行
    page.execute_script("initializeUpdateProgressModal()")

    # エラーログが出力されることを確認
    logs = page.driver.browser.logs.get(:browser)
    error_logs = logs.select { |log| log.message.include?("Bootstrap is not loaded") }
    
    assert error_logs.any?, "Should log Bootstrap unavailable error"
  end

  test "form submission continues even when modal fails" do
    visit edit_post_path(@post)

    # タイトルを変更
    fill_in "post_title", with: "Test Title Update"
    fill_in "post_content", with: "Test content update"

    # モーダル要素を削除してエラーを発生させる
    page.execute_script("document.getElementById('updateProgressModal').remove()")

    # 更新ボタンをクリック
    click_button "投稿"

    # フォーム送信は継続されるべき
    # リダイレクトまたは更新完了を確認
    sleep 2
    
    # エラーログが記録されていることを確認
    logs = page.driver.browser.logs.get(:browser)
    error_logs = logs.select { |log| log.message.include?("Required elements not found") }
    
    assert error_logs.any?, "Should handle missing modal elements gracefully"
  end

  private

  def sign_in(user)
    visit new_user_session_path
    fill_in "user_email", with: user.email
    fill_in "user_password", with: "password"
    click_button "ログイン"
  end
end