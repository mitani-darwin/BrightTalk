require "test_helper"

class CommentIpRestrictionTest < ActiveSupport::TestCase
  def restriction(country_db: FakeGeoipDatabase::COUNTRY, asn_db: FakeGeoipDatabase::ASN)
    CommentIpRestriction.new(country_db: country_db, asn_db: asn_db)
  end

  test "日本国内の一般回線からは許可されること" do
    assert_equal :allowed, restriction.check("203.0.113.1")
  end

  test "日本国外からは拒否されること" do
    assert_equal :foreign, restriction.check("203.0.113.2")
  end

  test "日本国内でもクラウド事業者のASNからは拒否されること" do
    assert_equal :hosting, restriction.check("203.0.113.3")
  end

  test "組織名にVPNを含むASNからは拒否されること" do
    assert_equal :hosting, restriction.check("203.0.113.4")
  end

  test "ASNが登録されていないIPは判定不可として拒否されること" do
    assert_equal :unavailable, restriction.check("203.0.113.5")
  end

  test "国が登録されていないIPは判定不可として拒否されること" do
    assert_equal :unavailable, restriction.check("127.0.0.1")
  end

  test "データベースが無い場合は判定不可として拒否されること" do
    assert_equal :unavailable, restriction(country_db: nil).check("203.0.113.1")
    assert_equal :unavailable, restriction(asn_db: nil).check("203.0.113.1")
  end

  test "不正なIPは判定不可として拒否されること" do
    assert_equal :unavailable, restriction.check("not-an-ip")
  end
end
