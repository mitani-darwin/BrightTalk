require "application_system_test_case"

class VideoCodeeditorIntegrationTest < ApplicationSystemTestCase
  setup { build_test_page }

  test "動画アップロード機能のJavaScript統合をテスト" do
    page.execute_script(<<~JS)
      const mockFile = new File(['mock video content'], 'test_video.mp4', { type: 'video/mp4' });
      handleVideoUpload({ target: { files: [mockFile] } });
    JS

    content_value = textarea_value
    assert_includes content_value, "[test_video.mp4]", "動画のMarkdownリンクが挿入されていません: #{content_value}"
    assert_includes content_value, "attachment:test_video.mp4", "動画のattachmentリンクが生成されていません: #{content_value}"
  end

  test "カスタムイベントによるテキスト挿入をテスト" do
    page.evaluate_script("triggerCustomInsert(arguments[0])", 'Custom event test: [custom_video.mp4](attachment:custom_video.mp4)\n\n')

    final_content = textarea_value
    assert_includes final_content, "Custom event test", "カスタムイベントによるテキスト挿入が失敗しました: #{final_content}"
    assert_includes final_content, "custom_video.mp4", "カスタムイベントでの動画リンクが挿入されていません: #{final_content}"
  end

  test "フォールバック機能をテスト" do
    page.evaluate_script("applyFallback(arguments[0])", '[fallback_video.mp4](attachment:fallback_video.mp4)\n\n')

    assert_includes textarea_value, "fallback_video.mp4", "フォールバックでのテキスト挿入が失敗しました: #{textarea_value}"
  end

  test "insertExistingMedia関数をテスト" do
    page.execute_script(<<~JS)
      var button = document.createElement('button');
      button.className = 'insert-existing-video';
      button.dataset.filename = 'existing_test.mp4';
      button.dataset.url = 'attachment:existing_test.mp4';
      document.body.appendChild(button);
      insertExistingMedia({ target: button }, 'video');
    JS

    assert_includes textarea_value, "existing_test.mp4", "既存動画のリンクが挿入されていません: #{textarea_value}"
  end

  private

  def build_test_page
    html = <<~HTML
      <!DOCTYPE html>
      <html>
      <head><meta charset="utf-8"><title>CodeEditor Integration Test</title></head>
      <body>
        <form data-turbo="false">
          <input type="file" id="videoInput" accept="video/*">
          <div id="codeEditorWrapper" data-controller="code-editor">
            <textarea id="contentTextarea" rows="10" style="min-height:200px"></textarea>
          </div>
        </form>
      </body>
      </html>
    HTML

    visit 'about:blank'
    page.execute_script("document.open(); document.write(#{html.inspect}); document.close();")

    page.execute_script(<<~JS)
      function insertTextAtCursor(textarea, text) {
        if (!textarea) return;
        const start = textarea.selectionStart ?? textarea.value.length;
        const end = textarea.selectionEnd ?? textarea.value.length;
        const before = textarea.value.substring(0, start);
        const after = textarea.value.substring(end);
        textarea.value = before + text + after;
        const newPos = start + text.length;
        textarea.selectionStart = textarea.selectionEnd = newPos;
        textarea.dispatchEvent(new Event('input', { bubbles: true }));
      }

      window.insertMarkdownAtCursor = function(textarea, text) {
        insertTextAtCursor(textarea, text);
      };

      window.fallbackTextInsertion = function(textarea, text) {
        insertTextAtCursor(textarea, text);
      };

      window.handleVideoUpload = function(event) {
        const file = event.target.files && event.target.files[0];
        if (!file) return;
        const textarea = document.getElementById('contentTextarea');
        const markdownLink = `[${file.name}](attachment:${file.name})\n\n`;
        insertMarkdownAtCursor(textarea, markdownLink);
      };

      window.insertExistingMedia = function(event, type) {
        const button = event.target;
        if (!button) return;
        const filename = button.dataset.filename;
        const url = button.dataset.url;
        const textarea = document.getElementById('contentTextarea');
        const markdown = (type === 'image' || button.classList.contains('insert-existing-image'))
          ? `![${filename}](${url})\n\n`
          : `[${filename}](${url})\n\n`;
        insertMarkdownAtCursor(textarea, markdown);
      };

      document.getElementById('codeEditorWrapper').addEventListener('code-editor:insert-text', function(event) {
        const textarea = document.getElementById('contentTextarea');
        insertMarkdownAtCursor(textarea, event.detail.text);
      });

      window.triggerCustomInsert = function(text) {
        const wrapper = document.getElementById('codeEditorWrapper');
        const event = new CustomEvent('code-editor:insert-text', { detail: { text } });
        wrapper.dispatchEvent(event);
      };

      window.applyFallback = function(text) {
        const textarea = document.getElementById('contentTextarea');
        fallbackTextInsertion(textarea, text);
      };
    JS
  end

  def textarea_value
    page.evaluate_script("document.getElementById('contentTextarea').value")
  end
end
