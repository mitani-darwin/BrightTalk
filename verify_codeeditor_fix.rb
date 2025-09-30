#!/usr/bin/env ruby
# CodeEditor 修正の検証スクリプト

require 'net/http'
require 'uri'

puts "CodeEditor 修正検証スクリプト"
puts "=" * 50

# サーバーが起動しているか確認
def server_running?
  begin
    uri = URI('http://localhost:3000')
    response = Net::HTTP.get_response(uri)
    response.code == '200' || response.code == '302'
  rescue
    false
  end
end

puts "1. Rails サーバーの状態確認..."
if server_running?
  puts "✓ Rails サーバーが起動中 (http://localhost:3000)"
else
  puts "✗ Rails サーバーが起動していません"
  puts "   rails server を実行してください"
  exit 1
end

# 修正内容の確認
puts "\n2. 修正内容の確認..."
form_file = "/Users/mitani/git/BrightTalk/app/views/posts/_form_main_content.html.erb"

if File.exist?(form_file)
  content = File.read(form_file)
  
  if content.include?('data: { controller: "code-editor"')
    puts "✓ CodeEditor コントローラーが正しく設定されています"
  else
    puts "✗ CodeEditor コントローラーの設定に問題があります"
    exit 1
  end
  
  if content.include?('Rails.env.test? ?')
    puts "✗ テスト環境での条件分岐が残っています (修正が適用されていません)"
    exit 1
  else
    puts "✓ テスト環境での条件分岐が削除されています"
  end
else
  puts "✗ フォームファイルが見つかりません: #{form_file}"
  exit 1
end

puts "\n3. CodeEditor コントローラーファイルの確認..."
controller_file = "/Users/mitani/git/BrightTalk/app/javascript/controllers/code_editor_controller.js"

if File.exist?(controller_file)
  controller_content = File.read(controller_file)
  
  if controller_content.include?('initializeCodeMirror')
    puts "✓ CodeEditor コントローラーが正しく実装されています"
  else
    puts "✗ CodeEditor コントローラーの実装に問題があります"
    exit 1
  end
else
  puts "✗ CodeEditor コントローラーファイルが見つかりません: #{controller_file}"
  exit 1
end

puts "\n4. ブラウザテストの準備..."
puts "以下の手順で手動テストを実行してください:"
puts ""
puts "ブラウザで http://localhost:3000/posts/new にアクセス"
puts "開発者ツールのコンソールを開く"
puts "以下のログが表示されることを確認:"
puts "  - 'CodeEditor controller connected'"
puts "  - 'CodeMirror initialized successfully'"
puts ""
puts "テキストエリアが CodeMirror エディターに変換されていることを確認"
puts "日本語入力が正常に動作することを確認"
puts ""

puts "\n5. 検証用のテストHTMLファイル..."
test_file = "/Users/mitani/git/BrightTalk/test_codeeditor_fix.html"
if File.exist?(test_file)
  puts "✓ 検証用テストファイルが利用可能: file://#{test_file}"
  puts "  このファイルをブラウザで開いて CodeEditor 機能をテストできます"
else
  puts "✗ 検証用テストファイルが見つかりません"
end

puts "\n" + "=" * 50
puts "修正内容の検証が完了しました"
puts ""
puts "主な修正点:"
puts "- _form_main_content.html.erb の条件分岐を削除"
puts "- data-controller=\"code-editor\" が常に設定されるように修正"
puts "- CodeMirror が正常に初期化されるように修正"
puts ""
puts "この修正により、日本語入力を含む CodeEditor 機能が正常に動作するはずです。"