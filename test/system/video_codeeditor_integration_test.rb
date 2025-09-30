require "application_system_test_case"

class VideoCodeeditorIntegrationTest < ApplicationSystemTestCase
  test "動画アップロード機能のJavaScript統合をテスト" do
    # テスト用の簡単なHTMLページを作成してテスト
    visit_test_page

    # 必要なHTML要素が存在することを確認
    assert_selector "#videoInput"
    assert_selector "#contentTextarea"
    assert_selector "[data-controller*='code-editor']"

    # JavaScript関数が正しく定義されていることを確認
    assert page.evaluate_script("typeof handleVideoUpload === 'function'")
    assert page.evaluate_script("typeof insertMarkdownAtCursor === 'function'")
    assert page.evaluate_script("typeof fallbackTextInsertion === 'function'")

    # CodeEditorの初期化を待機
    sleep 2

    # 動画ファイル選択をシミュレート
    page.execute_script(<<~JS
      const videoInput = document.getElementById('videoInput');
      const mockFile = new File(['mock video content'], 'test_video.mp4', { type: 'video/mp4' });
      const mockFileList = Object.create(FileList.prototype);
      mockFileList[0] = mockFile;
      Object.defineProperty(mockFileList, 'length', { value: 1 });
      
      Object.defineProperty(videoInput, 'files', {
        value: mockFileList,
        writable: false
      });
      
      // changeイベントを発火
      const changeEvent = new Event('change', { bubbles: true });
      videoInput.dispatchEvent(changeEvent);
    JS
    )

    # テキストが挿入されるまで少し待機
    sleep 2

    # エディターまたはテキストエリアにMarkdownリンクが挿入されたことを確認
    content_value = page.evaluate_script(<<~JS
      const textarea = document.getElementById('contentTextarea');
      const codeEditorElement = textarea.closest('[data-controller*="code-editor"]');
      
      // CodeMirrorエディターから値を取得
      if (window.CodeMirror && codeEditorElement) {
        const editor = codeEditorElement.querySelector('.CodeMirror');
        if (editor && editor.CodeMirror) {
          return editor.CodeMirror.getValue();
        }
      }
      
      // フォールバック: 通常のテキストエリアの値
      return textarea.value;
    JS
    )

    assert content_value.include?("[test_video.mp4]"), "動画のMarkdownリンクが挿入されていません: #{content_value}"
    assert content_value.include?("attachment:test_video.mp4"), "動画のattachmentリンクが正しく生成されていません: #{content_value}"
  end

  test "カスタムイベントによるテキスト挿入をテスト" do
    visit_test_page

    # CodeEditorの初期化を待機
    sleep 2

    # カスタムイベントでテキスト挿入をテスト
    page.execute_script(<<~JS
      var textarea = document.getElementById('contentTextarea');
      var codeEditorElement = textarea.closest('[data-controller*="code-editor"]');
      
      if (codeEditorElement) {
        var customEvent = new CustomEvent('code-editor:insert-text', {
          detail: { text: 'Custom event test: [custom_video.mp4](attachment:custom_video.mp4)\\n\\n' }
        });
        codeEditorElement.dispatchEvent(customEvent);
      }
    JS
    )

    # イベント処理まで少し待機
    sleep 1

    # テキストが挿入されたことを確認
    final_content = page.evaluate_script(<<~JS
      var textarea = document.getElementById('contentTextarea');
      var codeEditorElement = textarea.closest('[data-controller*="code-editor"]');
      
      if (window.CodeMirror && codeEditorElement) {
        var editor = codeEditorElement.querySelector('.CodeMirror');
        if (editor && editor.CodeMirror) {
          return editor.CodeMirror.getValue();
        }
      }
      
      return textarea.value;
    JS
    )

    assert final_content.include?("Custom event test"), "カスタムイベントによるテキスト挿入が失敗しました: #{final_content}"
    assert final_content.include?("custom_video.mp4"), "カスタムイベントでの動画リンクが挿入されていません: #{final_content}"
  end

  test "フォールバック機能をテスト" do
    visit_test_page

    # CodeMirrorを一時的に無効化
    page.execute_script("window.CodeMirror = undefined;")

    # フォールバック関数を直接テスト
    page.execute_script(<<~JS
      var textarea = document.getElementById('contentTextarea');
      if (typeof fallbackTextInsertion === 'function') {
        fallbackTextInsertion(textarea, '[fallback_video.mp4](attachment:fallback_video.mp4)\\n\\n');
      }
    JS
    )

    # フォールバック処理が完了するまで待機
    sleep 1

    # テキストエリアにテキストが挿入されたことを確認
    textarea_value = page.evaluate_script("document.getElementById('contentTextarea').value")
    assert textarea_value.include?("fallback_video.mp4"), "フォールバックでのテキスト挿入が失敗しました: #{textarea_value}"
  end

  test "insertExistingMedia関数をテスト" do
    visit_test_page

    # 既存メディア挿入ボタンをシミュレート
    page.execute_script(<<~JS
      // 既存動画挿入ボタンを作成
      var button = document.createElement('button');
      button.className = 'insert-existing-video';
      button.setAttribute('data-filename', 'existing_test.mp4');
      button.setAttribute('data-url', 'attachment:existing_test.mp4');
      button.textContent = '挿入';
      document.body.appendChild(button);
      
      // クリックイベントを発火
      button.click();
    JS
    )

    # 挿入処理が完了するまで待機
    sleep 1

    # エディターに動画リンクが挿入されたことを確認
    content_value = page.evaluate_script(<<~JS
      var textarea = document.getElementById('contentTextarea');
      var codeEditorElement = textarea.closest('[data-controller*="code-editor"]');
      
      if (window.CodeMirror && codeEditorElement) {
        var editor = codeEditorElement.querySelector('.CodeMirror');
        if (editor && editor.CodeMirror) {
          return editor.CodeMirror.getValue();
        }
      }
      
      return textarea.value;
    JS
    )

    assert content_value.include?("existing_test.mp4"), "既存動画のリンクが挿入されていません: #{content_value}"
  end

  private

  def visit_test_page
    # テスト用のHTMLページを作成
    test_html = <<~HTML
      <!DOCTYPE html>
      <html>
      <head>
        <meta charset="utf-8">
        <meta name="viewport" content="width=device-width, initial-scale=1">
        <title>Video Upload CodeEditor Integration Test</title>
        
        <!-- CodeMirror CSS -->
        <link rel="stylesheet" href="https://cdn.jsdelivr.net/npm/codemirror@5.65.16/lib/codemirror.css">
        
        <!-- Bootstrap CSS -->
        <link href="https://cdn.jsdelivr.net/npm/bootstrap@5.3.2/dist/css/bootstrap.min.css" rel="stylesheet">
        
        <!-- Font Awesome -->
        <link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.4.0/css/all.min.css">
      </head>
      <body>
        <div class="container mt-4">
          <h1>Video Upload CodeEditor Integration Test</h1>
          
          <!-- テスト用フォーム -->
          <form data-turbo="false">
            <div class="mb-3">
              <label for="videoInput" class="form-label">動画アップロード</label>
              <input type="file" id="videoInput" accept="video/*" class="form-control">
            </div>
            
            <div class="mb-3" data-controller="code-editor">
              <label for="contentTextarea" class="form-label">内容</label>
              <textarea id="contentTextarea" 
                        class="form-control" 
                        data-code-editor-target="textarea"
                        rows="10" 
                        style="min-height: 300px; font-family: Monaco, monospace;">
              </textarea>
            </div>
          </form>
        </div>

        <!-- CodeMirror JS -->
        <script src="https://cdn.jsdelivr.net/npm/codemirror@5.65.16/lib/codemirror.js"></script>
        <script src="https://cdn.jsdelivr.net/npm/codemirror@5.65.16/mode/markdown/markdown.js"></script>
        
        <!-- Stimulus JS -->
        <script type="module">
          import { Application, Controller } from "https://unpkg.com/@hotwired/stimulus/dist/stimulus.js"
          
          window.Stimulus = Application.start()

          // CodeEditorController の簡易版
          class CodeEditorController extends Controller {
            static targets = ["textarea"]
            
            connect() {
              this.initializeCodeMirror()
              this.setupCustomEventListeners()
            }
            
            async initializeCodeMirror() {
              const textarea = this.textareaTarget
              
              if (window.CodeMirror) {
                this.editor = window.CodeMirror.fromTextArea(textarea, {
                  mode: "markdown",
                  theme: "default",
                  lineNumbers: true,
                  lineWrapping: true
                })
                
                this.editor.on("change", () => {
                  textarea.value = this.editor.getValue()
                })
              }
            }
            
            setupCustomEventListeners() {
              this.element.addEventListener('code-editor:insert-text', (event) => {
                const text = event.detail.text
                if (text) {
                  this.insertText(text)
                }
              })
            }
            
            insertText(text) {
              if (this.editor) {
                const doc = this.editor.getDoc()
                const cursor = doc.getCursor()
                doc.replaceRange(text, cursor)
                this.editor.focus()
              } else {
                const textarea = this.textareaTarget
                const start = textarea.selectionStart
                const end = textarea.selectionEnd
                const before = textarea.value.substring(0, start)
                const after = textarea.value.substring(end)
                textarea.value = before + text + after
                textarea.selectionStart = textarea.selectionEnd = start + text.length
                textarea.focus()
              }
            }
          }
          
          Stimulus.register("code-editor", CodeEditorController)
        </script>

        <script>
          #{File.read(Rails.root.join('app/views/posts/_form_javascript.html.erb')).gsub(/<\/?script[^>]*>/, '')}
          
          // 初期化実行
          document.addEventListener('DOMContentLoaded', function() {
            initializeFormFeatures();
            initializeUploadHandlers();
          });
        </script>
      </body>
      </html>
    HTML

    # 一時ファイルとして保存
    temp_file = Rails.root.join('tmp', 'video_codeeditor_test.html')
    File.write(temp_file, test_html)
    
    # ファイルURLとして訪問
    visit "file://#{temp_file}"
  end
end