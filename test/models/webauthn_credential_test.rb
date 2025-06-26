# test/models/webauthn_credential_test.rb
require "test_helper"

class WebauthnCredentialTest < ActiveSupport::TestCase
  def setup
    @user = users(:test_user)
    @external_id = "test_credential_id_123"
    @public_key = "test_public_key_data"
  end

  test "有効な属性でWebAuthn認証情報が有効であること" do
    credential = WebauthnCredential.new(
      user: @user,
      external_id: @external_id,
      public_key: @public_key,
      nickname: "テストデバイス",
      sign_count: 0
    )
    assert credential.valid?, "WebauthnCredential should be valid but got errors: #{credential.errors.full_messages}"
  end

  test "ユーザーが必須であること" do
    credential = WebauthnCredential.new(
      user: nil,
      external_id: @external_id,
      public_key: @public_key,
      nickname: "テストデバイス",
      sign_count: 0
    )
    assert_not credential.valid?
    assert credential.errors[:user].present?
  end

  test "external_idが必須であること" do
    credential = WebauthnCredential.new(
      user: @user,
      external_id: nil,
      public_key: @public_key,
      nickname: "テストデバイス",
      sign_count: 0
    )
    assert_not credential.valid?
    assert credential.errors[:external_id].present?
  end

  test "public_keyが必須であること" do
    credential = WebauthnCredential.new(
      user: @user,
      external_id: @external_id,
      public_key: nil,
      nickname: "テストデバイス",
      sign_count: 0
    )
    assert_not credential.valid?
    assert credential.errors[:public_key].present?
  end

  test "nicknameなしでも有効であること" do
    credential = WebauthnCredential.new(
      user: @user,
      external_id: @external_id,
      public_key: @public_key,
      nickname: nil,
      sign_count: 0
    )
    # nicknameは必須でないため、有効であるべき
    assert credential.valid?, "WebauthnCredential should be valid without nickname but got errors: #{credential.errors.full_messages}"
  end

  test "sign_countが必須であること" do
    credential = WebauthnCredential.new(
      user: @user,
      external_id: @external_id,
      public_key: @public_key,
      nickname: "テストデバイス",
      sign_count: nil
    )
    assert_not credential.valid?
    assert credential.errors[:sign_count].present?
  end

  test "external_idが一意であること" do
    # 最初の認証情報を作成
    WebauthnCredential.create!(
      user: @user,
      external_id: @external_id,
      public_key: @public_key,
      nickname: "テストデバイス1",
      sign_count: 0
    )

    # 同じexternal_idで2つ目を作成しようとする
    duplicate_credential = WebauthnCredential.new(
      user: @user,
      external_id: @external_id,
      public_key: "different_public_key",
      nickname: "テストデバイス2",
      sign_count: 0
    )

    assert_not duplicate_credential.valid?
    assert duplicate_credential.errors[:external_id].present?
  end

  test "sign_countが負の値の場合無効であること" do
    credential = WebauthnCredential.new(
      user: @user,
      external_id: @external_id,
      public_key: @public_key,
      nickname: "テストデバイス",
      sign_count: -1
    )
    assert_not credential.valid?
    assert credential.errors[:sign_count].present?
  end

  test "ユーザーとの関連付けが正しく動作すること" do
    credential = WebauthnCredential.new(
      user: @user,
      external_id: @external_id,
      public_key: @public_key,
      nickname: "テストデバイス",
      sign_count: 0
    )
    assert_equal @user, credential.user
  end

  test "last_used_atが正しく更新されること" do
    credential = WebauthnCredential.create!(
      user: @user,
      external_id: @external_id,
      public_key: @public_key,
      nickname: "テストデバイス",
      sign_count: 0
    )

    # 最初は nil
    assert_nil credential.last_used_at

    # 使用時間を更新
    now = Time.current
    credential.update!(last_used_at: now, sign_count: 1)

    assert_equal now.to_i, credential.last_used_at.to_i
  end

  test "作成時間が自動的に設定されること" do
    credential = WebauthnCredential.create!(
      user: @user,
      external_id: @external_id,
      public_key: @public_key,
      nickname: "テストデバイス",
      sign_count: 0
    )
    assert_not_nil credential.created_at
    assert_not_nil credential.updated_at
  end

  test "nameメソッドが正しく動作すること" do
    # nicknameがある場合
    credential = WebauthnCredential.new(
      user: @user,
      external_id: @external_id,
      public_key: @public_key,
      nickname: "マイデバイス",
      sign_count: 0
    )
    assert_equal "マイデバイス", credential.name

    # nicknameがない場合
    credential_no_nickname = WebauthnCredential.new(
      user: @user,
      external_id: "another_id",
      public_key: @public_key,
      nickname: nil,
      sign_count: 0
    )
    assert_equal "WebAuthn認証", credential_no_nickname.name
  end

  test "name=メソッドが正しく動作すること" do
    credential = WebauthnCredential.new(
      user: @user,
      external_id: @external_id,
      public_key: @public_key,
      sign_count: 0
    )

    credential.name = "新しいデバイス名"
    assert_equal "新しいデバイス名", credential.nickname
    assert_equal "新しいデバイス名", credential.name
  end

  test "update_sign_count!メソッドが正しく動作すること" do
    credential = WebauthnCredential.create!(
      user: @user,
      external_id: @external_id,
      public_key: @public_key,
      nickname: "テストデバイス",
      sign_count: 0
    )

    old_time = credential.last_used_at
    new_count = 5

    credential.update_sign_count!(new_count)

    credential.reload
    assert_equal new_count, credential.sign_count
    assert_not_nil credential.last_used_at
    assert credential.last_used_at != old_time if old_time
  end
end
