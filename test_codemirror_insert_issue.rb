#!/usr/bin/env ruby

puts "=== CodeMirror画像・動画挿入問題の調査 ==="
puts "日時: #{Time.now}"
puts

# CodeMirrorバージョン情報
puts "=== CodeMirrorバージョン情報 ==="
package_json_path = "/Users/mitani/git/BrightTalk/package.json"
if File.exist?(package_json_path)
  require 'json'
  package_data = JSON.parse(File.read(package_json_path))
  
  codemirror_deps = package_data['dependencies'].select { |k, v| k.include?('codemirror') }
  codemirror_deps.each do |package, version|
    puts "  #{package}: #{version}"
  end
else
  puts "  package.jsonが見つかりません"
end
puts

# 重要なファイルの存在確認
puts "=== 重要ファイルの存在確認 ==="
important_files = [
  "/Users/mitani/git/BrightTalk/app/views/posts/_form_javascript.html.erb",
  "/Users/mitani/git/BrightTalk/app/javascript/controllers/code_editor_controller.js",
  "/Users/mitani/git/BrightTalk/app/javascript/application.js"
]

important_files.each do |file|
  exists = File.exist?(file)
  puts "  #{exists ? '✓' : '✗'} #{File.basename(file)}"
end
puts

# _form_javascript.html.erbの挿入関数の確認
puts "=== insertMarkdownAtCursor関数の分析 ==="
form_js_path = "/Users/mitani/git/BrightTalk/app/views/posts/_form_javascript.html.erb"
if File.exist?(form_js_path)
  content = File.read(form_js_path)
  
  # 重要な機能の存在確認
  checks = [
    ["insertMarkdownAtCursor関数", content.include?("function insertMarkdownAtCursor")],
    ["CodeMirror 6対応（.cm-editor）", content.include?(".cm-editor")],
    ["Stimulusコントローラーアクセス", content.include?("window.Stimulus.application.getControllerForElementAndIdentifier")],
    ["insertTextメソッド呼び出し", content.include?("controller.insertText")],
    ["キューイングシステム", content.include?("_insertQueue")],
    ["フォールバック処理", content.include?("フォールバック: 通常のテキストエリア処理")]
  ]
  
  checks.each do |name, exists|
    puts "  #{exists ? '✓' : '✗'} #{name}"
  end
else
  puts "  ✗ _form_javascript.html.erbが見つかりません"
end
puts

# code_editor_controller.jsの分析
puts "=== CodeEditorコントローラーの分析 ==="
controller_path = "/Users/mitani/git/BrightTalk/app/javascript/controllers/code_editor_controller.js"
if File.exist?(controller_path)
  content = File.read(controller_path)
  
  # 重要な機能の存在確認
  checks = [
    ["insertTextメソッド", content.include?("insertText(text)")],
    ["CodeMirror 6 API使用", content.include?("EditorView") && content.include?("EditorState")],
    ["初期化完了イベント", content.include?("dispatch('initialized'")],
    ["codemirror-initializedクラス", content.include?("codemirror-initialized")],
    ["コントローラー接続", content.include?("connect()")]
  ]
  
  checks.each do |name, exists|
    puts "  #{exists ? '✓' : '✗'} #{name}"
  end
else
  puts "  ✗ code_editor_controller.jsが見つかりません"
end
puts

# 潜在的な問題の特定
puts "=== 潜在的な問題の特定 ==="
potential_issues = []

if File.exist?(form_js_path)
  content = File.read(form_js_path)
  
  # CodeMirror 6の特定のAPIが使用されているかチェック
  unless content.include?("state.update") && content.include?("dispatch(transaction)")
    potential_issues << "CodeMirror 6の正しいAPIが使用されていない可能性"
  end
  
  # エラーハンドリングの確認
  unless content.include?("try {") && content.include?("catch")
    potential_issues << "エラーハンドリングが不十分"
  end
end

if potential_issues.any?
  potential_issues.each do |issue|
    puts "  ⚠️  #{issue}"
  end
else
  puts "  ✓ 明らかな問題は検出されませんでした"
end
puts

puts "=== 次のステップの推奨 ==="
puts "1. 実際のブラウザでの動作テスト"
puts "2. コンソールエラーログの確認"
puts "3. CodeMirror 6のAPI変更に対応した修正の実装"
puts "4. 挿入処理のデバッグとログの追加"
puts
puts "=== 調査完了 ==="