#!/usr/bin/env ruby
# テスト用スクリプト - textarea 修正の検証

puts "CodeEditor textarea 修正の検証"
puts "=" * 40

# 修正されたファイルの内容を確認
form_file = "/Users/mitani/git/BrightTalk/app/views/posts/_form_main_content.html.erb"

if File.exist?(form_file)
  content = File.read(form_file)
  
  puts "1. data属性の確認..."
  if content.include?('code_editor_target: "textarea"')
    puts "✓ 正しいdata属性形式が使用されています: code_editor_target"
  else
    puts "✗ data属性に問題があります"
  end
  
  if content.include?('"code-editor-target": "textarea"')
    puts "✗ 古いdata属性形式が残っています"
  else
    puts "✓ 古いdata属性形式は修正されています"
  end
  
  puts "\n2. HTML出力の確認..."
  puts "Rails によって以下のHTML属性が生成されます:"
  puts "data-code-editor-target=\"textarea\""
  puts ""
  puts "これにより、Stimulus の CodeEditor controller で"
  puts "this.textareaTarget が正常に動作するはずです。"
  
else
  puts "✗ フォームファイルが見つかりません: #{form_file}"
end

puts "\n" + "=" * 40
puts "次のステップ:"
puts "1. Rails サーバーを起動: rails server"
puts "2. ブラウザで http://localhost:3000/posts/new にアクセス"
puts "3. 開発者ツールで以下をチェック:"
puts "   console.log('Textarea found:', !!element?.querySelector('textarea'))"
puts "   → true になることを確認"