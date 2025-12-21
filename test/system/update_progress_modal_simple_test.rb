require "application_system_test_case"

class UpdateProgressModalSimpleTest < ApplicationSystemTestCase
  test "modal HTML elements exist" do
    # 簡単なHTMLページを作成してテスト
    visit_test_page

    # モーダル要素が存在することを確認
    assert_selector "#updateProgressModal", visible: :hidden
    assert_selector "#updateProgressBar", visible: :hidden
    assert_selector "#updateStatusText", visible: :hidden
    assert_selector "#updateDetails", visible: :hidden
    assert_selector "#updateProgressText", visible: :hidden
  end

  test "JavaScript functions are defined" do
    visit_test_page

    # JavaScript関数が定義されていることを確認
    assert_equal true, page.evaluate_script("typeof initializeUpdateProgressModal === 'function'")
    assert_equal true, page.evaluate_script("typeof handleUpdateSubmit === 'function'")
    assert_equal true, page.evaluate_script("typeof startUpdateProgress === 'function'")
  end

  test "progress animation updates elements" do
    visit_test_page

    # 初期状態の確認
    initial_width = page.evaluate_script("document.getElementById('updateProgressBar').style.width")
    assert_equal "0%", initial_width

    # プログレス開始
    page.execute_script("startUpdateProgress()")

    # 少し待機
    sleep 1

    # プログレスバーが更新されていることを確認
    updated_width = page.evaluate_script("document.getElementById('updateProgressBar').style.width")
    assert_not_equal "", updated_width
    assert_not_equal "0%", updated_width

    # ステータステキストが更新されていることを確認
    status_text = page.evaluate_script("document.getElementById('updateStatusText').textContent")
    assert_not_equal "準備中...", status_text
  end

  test "modal initialization handles missing elements gracefully" do
    visit_test_page

    # 必要な要素を削除
    page.execute_script("document.getElementById('updateProgressModal').remove()")

    # 初期化実行（エラーが発生しないことを確認）
    page.execute_script("initializeUpdateProgressModal()")

    # コンソールエラーがログに記録されていることを確認
    logs = page.driver.browser.logs.get(:browser)
    warning_logs = logs.select { |log| log.message.include?("Required elements not found") }
    
    # 警告ログが存在することを確認（関数が適切にエラーハンドリングしていることの証拠）
    assert warning_logs.any?, "Should handle missing elements gracefully"
  end

  test "modal toggles visibility without bootstrap" do
    visit_test_page

    assert_selector "#updateProgressModal", visible: :hidden
    page.execute_script("showProgressModal()")
    assert_selector "#updateProgressModal", visible: :visible
    page.execute_script("hideProgressModal()")
    assert_selector "#updateProgressModal", visible: :hidden
  end

  private

  def visit_test_page
    # テスト用の簡単なHTMLページを作成
    script_content = ApplicationController.render(partial: "posts/form_javascript")
    modal_content = ApplicationController.render(partial: "posts/upload_progress_modal")

    test_html = <<~HTML
      <!DOCTYPE html>
      <html>
      <head>
        <script src="https://cdn.tailwindcss.com?plugins=forms,typography&version=4.1.0"></script>
      </head>
      <body class="bg-slate-50">
        #{modal_content}
        <form data-turbo="false">
          <button type="submit" id="updateSubmitBtn" class="btn btn-primary mt-4">投稿</button>
        </form>

        #{script_content}
      </body>
      </html>
    HTML

    # 一時ファイルとして保存
    temp_file = Rails.root.join('tmp', 'test_modal.html')
    File.write(temp_file, test_html)
    
    # ファイルURLとして訪問
    visit "file://#{temp_file}"
  end
end
