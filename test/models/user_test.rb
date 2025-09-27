require "test_helper"

class UserTest < ActiveSupport::TestCase
  test "有効な属性でユーザーが有効であること" do
    user = User.new(
      name: "Test User New",
      email: "testnew@example.com"
    )
    assert user.valid?, "User should be valid but got errors: #{user.errors.full_messages}"
  end

  test "名前が必須であること" do
    user = User.new(
      email: "testnew2@example.com"
    )
    assert_not user.valid?
    assert_includes user.errors[:name], "を入力してください"
  end

  test "メールアドレスが必須であること" do
    user = User.new(
      name: "Test User"
    )
    assert_not user.valid?
    assert_includes user.errors[:email], "を入力してください"
  end
end
