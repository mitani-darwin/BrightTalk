
require "test_helper"

class ApplicationSystemTestCase < ActionDispatch::SystemTestCase
  # 環境変数でヘッドレスモードを制御
  if ENV["HEADLESS"] == "true" || ENV["CI"]
    driven_by :selenium, using: :headless_chrome, screen_size: [ 1400, 1400 ]
  else
    driven_by :selenium, using: :chrome, screen_size: [ 1400, 1400 ]
  end

  # 以下同じ...
  def after_teardown
    super
    if respond_to?(:take_screenshot) && !passed?
      take_screenshot
    end
  rescue => e
    puts "Could not take screenshot: #{e.message}"
  end

  def login_as(user, password: "Secure#P@ssw0rd9")
    visit new_user_session_path

    email_filled = false
    [ "user[email]", "user_email", "email" ].each do |field_name|
      if page.has_field?(field_name)
        fill_in field_name, with: user.email
        email_filled = true
        break
      end
    end

    unless email_filled
      if page.has_css?("input[type='email']")
        page.find("input[type='email']").set(user.email)
        email_filled = true
      end
    end

    assert email_filled, "Could not find email field"

    password_filled = false
    [ "user[password]", "user_password", "password" ].each do |field_name|
      if page.has_field?(field_name)
        fill_in field_name, with: password
        password_filled = true
        break
      end
    end

    unless password_filled
      if page.has_css?("input[type='password']")
        page.find("input[type='password']").set(password)
        password_filled = true
      end
    end

    assert password_filled, "Could not find password field"

    login_clicked = false
    [ "ログイン", "Log in", "Sign in" ].each do |button_text|
      if page.has_button?(button_text)
        click_button button_text
        login_clicked = true
        break
      end
    end

    unless login_clicked
      if page.has_css?("input[type='submit']")
        page.find("input[type='submit']").click
        login_clicked = true
      end
    end

    assert login_clicked, "Could not find login button"

    sleep 2

    error_messages = [ "Invalid Email or password", "メールアドレスまたはパスワードが違います" ]
    error_messages.each do |error_msg|
      assert_no_text error_msg, "Login failed with error: #{error_msg}"
    end
  end

  def logout
    logout_texts = [ "ログアウト", "Log out", "Sign out" ]
    logout_texts.each do |text|
      if page.has_link?(text)
        click_link text
        break
      end
    end
  end
end
