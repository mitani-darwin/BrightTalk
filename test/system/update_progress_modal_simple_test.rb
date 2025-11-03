require "application_system_test_case"

class UpdateProgressModalSimpleTest < ApplicationSystemTestCase
  test "modal HTML elements exist" do
    # 簡単なHTMLページを作成してテスト
    visit_test_page

    # モーダル要素が存在することを確認
    assert_selector "#updateProgressModal", visible: false
    assert_selector "#updateProgressBar", visible: false
    assert_selector "#updateStatusText", visible: false
    assert_selector "#updateDetails", visible: false
    assert_selector "#updateProgressText", visible: false
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

  test "bootstrap dependency check works" do
    visit_test_page

    # Bootstrap を一時的に無効化
    page.execute_script("window.bootstrapBackup = window.bootstrap; window.bootstrap = undefined")

    # 初期化実行
    page.execute_script("initializeUpdateProgressModal()")

    # エラーログが出力されることを確認
    logs = page.driver.browser.logs.get(:browser)
    bootstrap_error_logs = logs.select { |log| log.message.include?("Bootstrap is not loaded") }
    
    assert bootstrap_error_logs.any?, "Should detect Bootstrap unavailability"

    # Bootstrap を復元
    page.execute_script("window.bootstrap = window.bootstrapBackup")
  end

  private

  def visit_test_page
    # テスト用の簡単なHTMLページを作成
    script_content = ApplicationController.render(partial: "posts/form_javascript")

    test_html = <<~HTML
      <!DOCTYPE html>
      <html>
      <head>
        <link href="https://cdn.jsdelivr.net/npm/bootstrap@5.3.2/dist/css/bootstrap.min.css" rel="stylesheet">
        <script src="https://cdn.jsdelivr.net/npm/bootstrap@5.3.2/dist/js/bootstrap.bundle.min.js"></script>
      </head>
      <body>
        <!-- 更新進捗モーダル -->
        <div class="modal fade" id="updateProgressModal" tabindex="-1" aria-labelledby="updateProgressModalLabel" aria-hidden="true" data-bs-backdrop="static" data-bs-keyboard="false">
          <div class="modal-dialog modal-dialog-centered">
            <div class="modal-content">
              <div class="modal-header border-0">
                <h5 class="modal-title" id="updateProgressModalLabel">
                  <i class="fas fa-sync fa-spin me-2"></i>更新中...
                </h5>
              </div>
              <div class="modal-body text-center py-4">
                <div class="progress mb-3" style="height: 12px;">
                  <div id="updateProgressBar"
                       class="progress-bar progress-bar-striped progress-bar-animated bg-primary"
                       role="progressbar"
                       style="width: 0%"
                       aria-valuenow="0"
                       aria-valuemin="0"
                       aria-valuemax="100">
                    <span id="updateProgressText">0%</span>
                  </div>
                </div>
                <div class="mb-3">
                  <span id="updateStatusText" class="text-muted">準備中...</span>
                </div>
                <div class="small text-muted">
                  <div id="updateDetails">投稿データを処理しています...</div>
                </div>
              </div>
            </div>
          </div>
        </div>

        <form data-turbo="false">
          <button type="submit" id="updateSubmitBtn" class="btn btn-primary">投稿</button>
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
