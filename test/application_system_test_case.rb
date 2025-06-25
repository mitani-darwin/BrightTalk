require "test_helper"

class ApplicationSystemTestCase < ActionDispatch::SystemTestCase
  if ENV["CI"]
    driven_by :selenium, using: :headless_chrome, screen_size: [1400, 1400] do |driver_options|
      driver_options.add_argument("--disable-dev-shm-usage")
      driver_options.add_argument("--no-sandbox")
      driver_options.add_argument("--disable-gpu")
      driver_options.add_argument("--disable-extensions")
      driver_options.add_argument("--disable-dev-tools")
    end
  else
    driven_by :selenium, using: :chrome, screen_size: [1400, 1400]
  end

  setup do
    Capybara.app_host = "http://127.0.0.1"
    Capybara.default_max_wait_time = 10
  end

  # システムテスト用のログインヘルパー
  def login_as(user)
    # 直接パスワード認証ルートを使用
    visit new_user_session_path

    # WebAuthn用のJavaScriptを無効化し、直接パスワードフォームを表示
    page.execute_script("
      document.getElementById('email-form').style.display = 'none';
      document.getElementById('password-form').style.display = 'block';
      document.getElementById('email-hidden').value = '#{user.email}';
    ")

    fill_in "password", with: "Secure#P@ssw0rd9"
    click_button "ログイン"
  end
end