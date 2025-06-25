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
    fill_in "user[email]", with: user.email
    fill_in "user[password]", with: password
    click_button "ログイン"
  end

  # ログアウトヘルパーメソッド
  def logout
    click_link "ログアウト" if page.has_link?("ログアウト")
  end
end