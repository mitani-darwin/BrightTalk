#!/usr/bin/env ruby

# Simple degression check without WebRick dependency
class SimpleDegressionCheck
  def initialize
    @results = {}
  end

  def check_stimulus_initialization_fix
    puts "=== Stimulusコントローラー初期化修正の確認 ==="
    
    # Check the fix in _form_javascript.html.erb
    form_js_path = 'app/views/posts/_form_javascript.html.erb'
    
    if File.exist?(form_js_path)
      content = File.read(form_js_path)
      
      # Check for the fixed condition
      if content.include?('textarea.nextElementSibling?.classList?.contains(\'CodeMirror\')')
        puts "✅ 修正が正しく適用されています: nextElementSibling?.classList?.contains を使用"
        @results[:stimulus_fix] = :success
        
        # Check that old incorrect code is not present
        if content.include?('textarea.nextSibling?.className?.includes(\'CodeMirror\')')
          puts "⚠️  古い不正なコードが残っています"
          @results[:stimulus_fix] = :warning
        end
        
      else
        puts "❌ 修正が適用されていません"
        @results[:stimulus_fix] = :failed
      end
    else
      puts "❌ ファイルが見つかりません: #{form_js_path}"
      @results[:stimulus_fix] = :failed
    end
  end

  def check_selectedfiles_variable
    puts "\n=== selectedFiles変数の確認 ==="
    
    form_js_path = 'app/views/posts/_form_javascript.html.erb'
    
    if File.exist?(form_js_path)
      content = File.read(form_js_path)
      
      # Check for selectedFiles declaration
      if content.include?('let selectedFiles = [];')
        puts "✅ selectedFiles変数が正しく宣言されています"
        @results[:selectedfiles] = :success
      else
        puts "❌ selectedFiles変数が宣言されていません"
        @results[:selectedfiles] = :failed
      end
    else
      puts "❌ ファイルが見つかりません: #{form_js_path}"
      @results[:selectedfiles] = :failed
    end
  end

  def check_codemirror_access_improvement
    puts "\n=== CodeMirror直接アクセス改善の確認 ==="
    
    form_js_path = 'app/views/posts/_form_javascript.html.erb'
    
    if File.exist?(form_js_path)
      content = File.read(form_js_path)
      
      improvements_found = 0
      
      # Check for improved Stimulus controller access
      if content.include?('Array.from(application.controllers).find(')
        puts "✅ 改善されたStimulusコントローラーアクセス方式"
        improvements_found += 1
      end
      
      # Check for direct CodeMirror access
      if content.include?('const cmWrapper = textarea.nextElementSibling;') && 
         content.include?('const cmInstance = cmWrapper.CodeMirror;')
        puts "✅ 直接CodeMirrorアクセス機能"
        improvements_found += 1
      end
      
      # Check for proper event handling
      if content.include?('code-editor:insert-text') && content.include?('bubbles: false')
        puts "✅ 改善されたカスタムイベント処理"
        improvements_found += 1
      end
      
      if improvements_found >= 2
        @results[:codemirror_access] = :success
        puts "✅ CodeMirrorアクセス機能が適切に改善されています"
      elsif improvements_found >= 1
        @results[:codemirror_access] = :warning
        puts "⚠️  一部の改善が適用されています"
      else
        @results[:codemirror_access] = :failed
        puts "❌ CodeMirrorアクセス改善が適用されていません"
      end
    else
      puts "❌ ファイルが見つかりません: #{form_js_path}"
      @results[:codemirror_access] = :failed
    end
  end

  def check_code_editor_controller
    puts "\n=== CodeEditorコントローラーの確認 ==="
    
    controller_path = 'app/javascript/controllers/code_editor_controller.js'
    
    if File.exist?(controller_path)
      content = File.read(controller_path)
      
      checks_passed = 0
      
      # Check for proper initialization
      if content.include?('codemirror-initialized') && content.include?('codemirror-initializing')
        puts "✅ 適切な初期化フラグ管理"
        checks_passed += 1
      end
      
      # Check for event listener
      if content.include?('handleInsertText') && content.include?('code-editor:insert-text')
        puts "✅ カスタムイベントリスナー"
        checks_passed += 1
      end
      
      # Check for insertText method
      if content.include?('insertText(text)') && content.include?('replaceRange')
        puts "✅ テキスト挿入機能"
        checks_passed += 1
      end
      
      if checks_passed >= 3
        @results[:controller] = :success
        puts "✅ CodeEditorコントローラーは正常です"
      elsif checks_passed >= 2
        @results[:controller] = :warning
        puts "⚠️  CodeEditorコントローラーは部分的に正常です"
      else
        @results[:controller] = :failed
        puts "❌ CodeEditorコントローラーに問題があります"
      end
    else
      puts "❌ ファイルが見つかりません: #{controller_path}"
      @results[:controller] = :failed
    end
  end

  def check_recent_commits_impact
    puts "\n=== 最近のコミットの影響確認 ==="
    
    begin
      # Get recent commit messages
      recent_commits = `git log --oneline -5 2>/dev/null`.strip
      
      if recent_commits.empty?
        puts "⚠️  Git履歴を取得できませんでした"
        @results[:commits] = :warning
        return
      end
      
      puts "最近のコミット:"
      recent_commits.split("\n").each { |commit| puts "  #{commit}" }
      
      # Check for potentially problematic commits
      problematic_keywords = ['修正', 'fix', 'bug', 'issue', 'error']
      problem_commits = recent_commits.lines.select do |line|
        problematic_keywords.any? { |keyword| line.downcase.include?(keyword) }
      end
      
      if problem_commits.any?
        puts "✅ 問題修正関連のコミットが確認されています"
        @results[:commits] = :success
      else
        puts "⚠️  最近の修正コミットが見当たりません"
        @results[:commits] = :warning
      end
      
    rescue => e
      puts "❌ Git情報の取得に失敗: #{e.message}"
      @results[:commits] = :failed
    end
  end

  def generate_summary
    puts "\n" + "="*50
    puts "デグレッション確認結果サマリー"
    puts "="*50
    
    success_count = @results.values.count(:success)
    warning_count = @results.values.count(:warning)
    failed_count = @results.values.count(:failed)
    total_count = @results.size
    
    @results.each do |check, result|
      status_icon = case result
                   when :success then "✅"
                   when :warning then "⚠️ "
                   when :failed then "❌"
                   else "❓"
                   end
      
      check_name = check.to_s.gsub('_', ' ').upcase
      puts "#{status_icon} #{check_name}"
    end
    
    puts "\n総合結果:"
    puts "  成功: #{success_count}/#{total_count}"
    puts "  警告: #{warning_count}/#{total_count}"
    puts "  失敗: #{failed_count}/#{total_count}"
    
    if failed_count == 0 && warning_count == 0
      puts "\n🎉 すべてのチェックが成功しました。デグレッションは修正されています。"
      return :excellent
    elsif failed_count == 0
      puts "\n👍 主要な問題は修正されていますが、軽微な警告があります。"
      return :good
    elsif failed_count <= total_count / 2
      puts "\n😐 一部の問題が残っています。追加の修正が必要です。"
      return :needs_work
    else
      puts "\n😞 重大な問題が検出されました。大幅な修正が必要です。"
      return :critical
    end
  end

  def run_all_checks
    puts "デグレッション確認開始...\n"
    
    check_stimulus_initialization_fix
    check_selectedfiles_variable
    check_codemirror_access_improvement
    check_code_editor_controller
    check_recent_commits_impact
    
    result = generate_summary
    
    # Return success status
    case result
    when :excellent, :good
      return true
    else
      return false
    end
  end
end

# Run the check
if __FILE__ == $0
  checker = SimpleDegressionCheck.new
  success = checker.run_all_checks
  exit(success ? 0 : 1)
end