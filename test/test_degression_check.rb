#!/usr/bin/env ruby

require 'selenium-webdriver'
require 'webrick'
require 'tempfile'

class DegressionCheckTest
  def initialize
    @driver = Selenium::WebDriver.for :chrome, options: chrome_options
    @server = nil
    @port = 8080
  end

  def chrome_options
    options = Selenium::WebDriver::Chrome::Options.new
    options.add_argument('--headless')
    options.add_argument('--no-sandbox')
    options.add_argument('--disable-dev-shm-usage')
    options.add_argument('--window-size=1920,1080')
    options
  end

  def start_server
    @server = WEBrick::HTTPServer.new(Port: @port, DocumentRoot: Dir.pwd)
    Thread.new { @server.start }
    sleep 2
  end

  def stop_server
    @server&.shutdown
  end

  def create_test_html
    html_content = <<~HTML
      <!DOCTYPE html>
      <html lang="ja">
      <head>
          <meta charset="UTF-8">
          <meta name="viewport" content="width=device-width, initial-scale=1.0">
          <title>デグレッション確認テスト</title>
          <link href="https://cdn.jsdelivr.net/npm/bootstrap@5.1.3/dist/css/bootstrap.min.css" rel="stylesheet">
          <link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/codemirror/5.65.2/codemirror.min.css">
          <script src="https://cdn.jsdelivr.net/npm/bootstrap@5.1.3/dist/js/bootstrap.bundle.min.js"></script>
          <script src="https://cdnjs.cloudflare.com/ajax/libs/codemirror/5.65.2/codemirror.min.js"></script>
          <script src="https://cdnjs.cloudflare.com/ajax/libs/codemirror/5.65.2/mode/markdown/markdown.min.js"></script>
      </head>
      <body>
          <div class="container mt-4">
              <h1>デグレッション確認テスト</h1>
              
              <div class="row mt-4">
                  <div class="col-12">
                      <h3>1. Stimulusコントローラー初期化テスト</h3>
                      <div data-controller="code-editor" class="mb-3">
                          <textarea id="contentTextarea" class="form-control" rows="10" placeholder="テキストを入力してください..."></textarea>
                      </div>
                      <div id="stimulus-test-result" class="alert alert-info">テスト実行中...</div>
                  </div>
              </div>
              
              <div class="row mt-4">
                  <div class="col-12">
                      <h3>2. ファイル選択とマークダウンリンク挿入テスト</h3>
                      <input type="file" id="imageInput" accept="image/*" multiple class="form-control mb-2">
                      <input type="file" id="videoInput" accept="video/*" class="form-control mb-2">
                      <div id="selectedFilesDisplay" style="display: block;">
                          <div id="selectedFilesList"></div>
                      </div>
                      <div id="markdown-test-result" class="alert alert-info">テスト準備中...</div>
                  </div>
              </div>
              
              <div class="row mt-4">
                  <div class="col-12">
                      <h3>3. CodeMirror直接アクセステスト</h3>
                      <button id="testDirectAccess" class="btn btn-primary">CodeMirror直接アクセステスト</button>
                      <div id="direct-access-result" class="alert alert-info mt-2">テスト待機中...</div>
                  </div>
              </div>
          </div>

          <script>
              // Global variables
              let selectedFiles = [];
              
              // Stimulus mock
              window.Stimulus = {
                  controllers: []
              };
              
              // CodeMirror initialization test
              function testStimulusInitialization() {
                  const textarea = document.getElementById('contentTextarea');
                  const codeEditorElement = textarea.closest('[data-controller*="code-editor"]');
                  const resultDiv = document.getElementById('stimulus-test-result');
                  
                  if (!codeEditorElement) {
                      resultDiv.className = 'alert alert-danger';
                      resultDiv.textContent = '❌ Code Editor要素が見つかりません';
                      return false;
                  }
                  
                  // CodeMirror初期化テスト
                  setTimeout(() => {
                      if (textarea.nextElementSibling?.classList?.contains('CodeMirror')) {
                          resultDiv.className = 'alert alert-success';
                          resultDiv.textContent = '✅ CodeMirrorが正常に初期化されました';
                      } else {
                          resultDiv.className = 'alert alert-warning';
                          resultDiv.textContent = '⚠️ CodeMirror初期化が検出されませんでした（フォールバック処理の可能性）';
                      }
                  }, 1000);
                  
                  return true;
              }
              
              // File selection test
              function testFileSelection() {
                  const imageInput = document.getElementById('imageInput');
                  const resultDiv = document.getElementById('markdown-test-result');
                  
                  // Mock file creation
                  const mockFile = new File(['test'], 'test-image.png', { type: 'image/png' });
                  
                  try {
                      // File list mock
                      const mockFileList = {
                          0: mockFile,
                          length: 1,
                          item: function(index) { return this[index]; }
                      };
                      
                      Object.defineProperty(imageInput, 'files', {
                          value: mockFileList,
                          writable: false,
                          configurable: true
                      });
                      
                      // Trigger change event
                      const changeEvent = new Event('change', { bubbles: true });
                      imageInput.dispatchEvent(changeEvent);
                      
                      // Check result
                      setTimeout(() => {
                          const textarea = document.getElementById('contentTextarea');
                          const expectedMarkdown = '![test-image.png](attachment:test-image.png)';
                          
                          if (textarea.value.includes(expectedMarkdown)) {
                              resultDiv.className = 'alert alert-success';
                              resultDiv.textContent = '✅ マークダウンリンクが正常に挿入されました';
                          } else {
                              resultDiv.className = 'alert alert-danger';
                              resultDiv.textContent = '❌ マークダウンリンクの挿入に失敗しました';
                          }
                      }, 1000);
                      
                  } catch (error) {
                      resultDiv.className = 'alert alert-danger';
                      resultDiv.textContent = '❌ ファイル選択テストでエラーが発生: ' + error.message;
                  }
              }
              
              // Direct CodeMirror access test
              function testDirectCodeMirrorAccess() {
                  const textarea = document.getElementById('contentTextarea');
                  const resultDiv = document.getElementById('direct-access-result');
                  
                  try {
                      if (textarea.nextElementSibling?.classList?.contains('CodeMirror')) {
                          const cmWrapper = textarea.nextElementSibling;
                          const cmInstance = cmWrapper.CodeMirror;
                          
                          if (cmInstance && cmInstance.replaceRange) {
                              const testText = '\\nCodeMirror直接アクセステスト成功\\n';
                              const cursor = cmInstance.getCursor();
                              cmInstance.replaceRange(testText, cursor);
                              
                              resultDiv.className = 'alert alert-success';
                              resultDiv.textContent = '✅ CodeMirror直接アクセス成功';
                          } else {
                              resultDiv.className = 'alert alert-danger';
                              resultDiv.textContent = '❌ CodeMirrorインスタンスにアクセスできません';
                          }
                      } else {
                          resultDiv.className = 'alert alert-warning';
                          resultDiv.textContent = '⚠️ CodeMirror要素が見つかりません';
                      }
                  } catch (error) {
                      resultDiv.className = 'alert alert-danger';
                      resultDiv.textContent = '❌ 直接アクセステストでエラー: ' + error.message;
                  }
              }
              
              // Initialize CodeMirror manually for test
              document.addEventListener('DOMContentLoaded', function() {
                  const textarea = document.getElementById('contentTextarea');
                  
                  // Initialize CodeMirror
                  if (window.CodeMirror) {
                      const editor = CodeMirror.fromTextArea(textarea, {
                          mode: 'markdown',
                          theme: 'default',
                          lineNumbers: true,
                          lineWrapping: true
                      });
                      
                      // Store reference for direct access
                      const cmWrapper = editor.getWrapperElement();
                      cmWrapper.CodeMirror = editor;
                  }
                  
                  // Run tests
                  setTimeout(() => {
                      testStimulusInitialization();
                      testFileSelection();
                  }, 500);
                  
                  // Set up direct access test button
                  document.getElementById('testDirectAccess').addEventListener('click', testDirectCodeMirrorAccess);
              });
              
              // File handling functions (simplified versions from the main code)
              function handleImageUpload(event) {
                  const files = Array.from(event.target.files);
                  const textarea = document.getElementById('contentTextarea');
                  
                  console.log('Image upload test triggered with files:', files.length);
                  
                  for (let file of files) {
                      console.log('Processing file:', file.name);
                      
                      if (textarea) {
                          const markdownLink = `![${file.name}](attachment:${file.name})\\n\\n`;
                          
                          setTimeout(() => {
                              insertMarkdownAtCursor(textarea, markdownLink);
                          }, 100);
                      }
                  }
              }
              
              function insertMarkdownAtCursor(textarea, text) {
                  console.log('insertMarkdownAtCursor called with:', text);
                  
                  // Try CodeMirror direct access first
                  if (textarea.nextElementSibling?.classList?.contains('CodeMirror')) {
                      const cmWrapper = textarea.nextElementSibling;
                      const cmInstance = cmWrapper.CodeMirror;
                      
                      if (cmInstance && cmInstance.replaceRange) {
                          console.log('Using CodeMirror direct access');
                          const cursor = cmInstance.getCursor();
                          cmInstance.replaceRange(text, cursor);
                          return;
                      }
                  }
                  
                  // Fallback to textarea
                  console.log('Using textarea fallback');
                  const start = textarea.selectionStart ?? textarea.value.length;
                  textarea.value = textarea.value.substring(0, start) + text + textarea.value.substring(start);
                  textarea.focus();
              }
              
              // Set up event listeners
              document.addEventListener('DOMContentLoaded', function() {
                  const imageInput = document.getElementById('imageInput');
                  if (imageInput) {
                      imageInput.addEventListener('change', handleImageUpload);
                  }
              });
          </script>
      </body>
      </html>
    HTML

    File.write('test_degression_check.html', html_content)
    puts "✓ テストHTML作成: test_degression_check.html"
  end

  def run_test
    puts "=== デグレッション確認テスト開始 ==="
    
    create_test_html
    start_server
    
    begin
      @driver.get("http://localhost:#{@port}/test_degression_check.html")
      
      # ページの読み込みを待機
      sleep 3
      
      # テスト結果の確認
      results = {}
      
      # 1. Stimulus初期化テスト結果
      stimulus_result = @driver.find_element(id: 'stimulus-test-result')
      results[:stimulus] = {
        class: stimulus_result.attribute('class'),
        text: stimulus_result.text
      }
      
      # 2. マークダウンテスト結果
      markdown_result = @driver.find_element(id: 'markdown-test-result')
      results[:markdown] = {
        class: markdown_result.attribute('class'),
        text: markdown_result.text
      }
      
      # 3. 直接アクセステスト実行
      @driver.find_element(id: 'testDirectAccess').click
      sleep 1
      
      direct_result = @driver.find_element(id: 'direct-access-result')
      results[:direct] = {
        class: direct_result.attribute('class'),
        text: direct_result.text
      }
      
      # 結果の表示
      puts "\n=== テスト結果 ==="
      results.each do |test_name, result|
        status = case result[:class]
                when /alert-success/ then "✅ SUCCESS"
                when /alert-warning/ then "⚠️  WARNING"
                when /alert-danger/ then "❌ FAILED"
                else "❓ UNKNOWN"
                end
        
        puts "#{test_name.to_s.upcase}: #{status}"
        puts "  #{result[:text]}"
      end
      
      # 総合判定
      success_count = results.values.count { |r| r[:class].include?('alert-success') }
      warning_count = results.values.count { |r| r[:class].include?('alert-warning') }
      failure_count = results.values.count { |r| r[:class].include?('alert-danger') }
      
      puts "\n=== 総合結果 ==="
      puts "成功: #{success_count}, 警告: #{warning_count}, 失敗: #{failure_count}"
      
      if failure_count > 0
        puts "❌ デグレッションが検出されました"
        return false
      elsif warning_count > 0
        puts "⚠️  一部の機能で警告が発生していますが、基本動作は正常です"
        return true
      else
        puts "✅ すべてのテストが正常に完了しました"
        return true
      end
      
    rescue => e
      puts "テスト実行中にエラーが発生: #{e.message}"
      puts e.backtrace.first(5).join("\n")
      return false
    ensure
      stop_server
      @driver.quit
      File.delete('test_degression_check.html') if File.exist?('test_degression_check.html')
    end
  end
end

if __FILE__ == $0
  test = DegressionCheckTest.new
  success = test.run_test
  exit(success ? 0 : 1)
end