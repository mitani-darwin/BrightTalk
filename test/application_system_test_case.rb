require "test_helper"

class ApplicationSystemTestCase < ActionDispatch::SystemTestCase
  driven_by :selenium, using: :chrome, screen_size: [1400, 1400]

  # ヘッドレスモードでChromeを実行（CI環境対応）
  if ENV["CI"]
    driven_by :selenium, using: :headless_chrome, screen_size: [1400, 1400]
  end

  # ログインヘルパーメソッド
  def login_as(user, password: "Secure#P@ssw0rd9")
    visit new_user_session_path

    # デバッグ用にページの内容を確認
    puts "Current URL: #{current_url}"
    puts "Page source contains 'email': #{page.has_content?('email')}"

    # 複数のパターンでフィールドを探す
    if page.has_field?("user[email]")
      fill_in "user[email]", with: user.email
    elsif page.has_field?("user_email")
      fill_in "user_email", with: user.email
    elsif page.has_field?("email")
      fill_in "email", with: user.email
    elsif page.has_css?("input[type='email']")
      find("input[type='email']").set(user.email)
    else
      # フィールドが見つからない場合はエラーメッセージを出力
      puts "Available input fields:"
      page.all('input').each do |input|
        puts "- #{input[:name]} (#{input[:type]}): #{input[:id]}"
      end
      raise "Could not find email input field"
    end

    # パスワードフィールドも同様に処理
    if page.has_field?("user[password]")
      fill_in "user[password]", with: password
    elsif page.has_field?("user_password")
      fill_in "user_password", with: password
    elsif page.has_field?("password")
      fill_in "password", with: password
    elsif page.has_css?("input[type='password']")
      find("input[type='password']").set(password)
    end

    # ログインボタンをクリック
    if page.has_button?("ログイン")
      click_button "ログイン"
    elsif page.has_button?("Log in")
      click_button "Log in"
    elsif page.has_button?("Sign in")
      click_button "Sign in"
    elsif page.has_css?("input[type='submit']")
      find("input[type='submit']").click
    end

    # ログイン成功を確認
    assert_no_text "Invalid Email or password", wait: 5
  end

  # ログアウトヘルパーメソッド
  def logout
    if page.has_link?("ログアウト")
      click_link "ログアウト"
    elsif page.has_link?("Log out")
      click_link "Log out"
    elsif page.has_link?("Sign out")
      click_link "Sign out"
    end
  end
end