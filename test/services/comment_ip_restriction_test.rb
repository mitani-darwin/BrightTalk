require "test_helper"

class CommentIpRestrictionTest < ActiveSupport::TestCase
  JAPAN = IpRangeSet.from_cidrs([ "203.0.113.0/25", "2001:db8::/32" ])
  HOSTING = IpRangeSet.from_cidrs([ "203.0.113.64/26", "2001:db8:ffff::/48", "198.51.100.128/25" ])

  def restriction(japan: JAPAN, hosting: HOSTING)
    CommentIpRestriction.new(japan: japan, hosting: hosting)
  end

  test "日本の一般回線からは許可されること" do
    assert_equal :allowed, restriction.check("203.0.113.1")
    assert_equal :allowed, restriction.check("2001:db8::1")
  end

  test "日本国外からは拒否されること" do
    assert_equal :foreign, restriction.check("198.51.100.1")
    assert_equal :foreign, restriction.check("2001:db9::1")
  end

  test "日本の範囲でもクラウド・ホスティング事業者の範囲からは拒否されること" do
    assert_equal :hosting, restriction.check("203.0.113.100")
    assert_equal :hosting, restriction.check("2001:db8:ffff::1")
  end

  test "日本国外に登録されたクラウド事業者の範囲はVPNとして拒否されること" do
    assert_equal :hosting, restriction.check("198.51.100.200")
  end

  test "IP範囲リストが無い場合は判定不可として拒否されること" do
    assert_equal :unavailable, restriction(japan: nil).check("203.0.113.1")
    assert_equal :unavailable, restriction(hosting: nil).check("203.0.113.1")
  end

  test "不正なIPは判定不可として拒否されること" do
    assert_equal :unavailable, restriction.check("not-an-ip")
  end
end
