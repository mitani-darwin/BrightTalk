require "test_helper"

class UserTest < ActiveSupport::TestCase
  test "有効な属性でユーザーが有効であること" do
    user = User.new(
      name: "Test User New",
      email: "testnew@example.com",
      password: "Secure#P@ssw0rd9",
      password_confirmation: "Secure#P@ssw0rd9"
    )
    assert user.valid?, "User should be valid but got errors: #{user.errors.full_messages}"
  end

  test "名前が必須であること" do
    user = User.new(
      email: "testnew2@example.com",
      password: "Secure#P@ssw0rd9",
      password_confirmation: "Secure#P@ssw0rd9"
    )
    assert_not user.valid?
    assert_includes user.errors[:name], "を入力してください"
  end

  test "メールアドレスが必須であること" do
    user = User.new(
      name: "Test User",
      password: "Secure#P@ssw0rd9",
      password_confirmation: "Secure#P@ssw0rd9"
    )
    assert_not user.valid?
    assert_includes user.errors[:email], "を入力してください"
  end

  test "弱いパスワードを拒否すること" do
    user = User.new(
      name: "Test User Weak",
      email: "testweak@example.com",
      password: "password123",
      password_confirmation: "password123"
    )
    assert_not user.valid?
    assert_includes user.errors[:password], "は英字、数字、記号をそれぞれ1文字以上含み、推測されにくいものにしてください"
  end

  test "強いパスワードを受け入れること" do
    user = User.new(
      name: "Test User Strong",
      email: "teststrong@example.com",
      password: "MyStr0ng#Pass!",
      password_confirmation: "MyStr0ng#Pass!"
    )
    assert user.valid?, "User should be valid but got errors: #{user.errors.full_messages}"
  end

  test "連続した数字を含むパスワードを拒否すること" do
    user = User.new(
      name: "Test Sequential",
      email: "testseq@example.com",
      password: "Password123!",
      password_confirmation: "Password123!"
    )
    assert_not user.valid?
    assert_includes user.errors[:password], "は英字、数字、記号をそれぞれ1文字以上含み、推測されにくいものにしてください"
  end

  test "ユーザー名を含むパスワードを拒否すること" do
    user = User.new(
      name: "TestUser",
      email: "testname@example.com",
      password: "TestUser789!",
      password_confirmation: "TestUser789!"
    )
    assert_not user.valid?
    assert_includes user.errors[:password], "は英字、数字、記号をそれぞれ1文字以上含み、推測されにくいものにしてください"
  end
end
