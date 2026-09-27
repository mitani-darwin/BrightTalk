require "test_helper"

class IpRangeSetTest < ActiveSupport::TestCase
  test "範囲の先頭・末尾を含み、その外側は含まないこと" do
    set = IpRangeSet.from_cidrs([ "192.0.2.0/24" ])

    assert set.include?("192.0.2.0")
    assert set.include?("192.0.2.255")
    assert_not set.include?("192.0.1.255")
    assert_not set.include?("192.0.3.0")
  end

  test "重なる範囲・隣接する範囲が結合されること" do
    set = IpRangeSet.from_cidrs([ "192.0.2.0/25", "192.0.2.128/25", "192.0.2.0/26", "198.51.100.0/24" ])

    assert_equal 2, set.size
    assert set.include?("192.0.2.200")
    assert set.include?("198.51.100.1")
    assert_not set.include?("192.0.3.1")
  end

  test "IPv4とIPv6を区別して判定すること" do
    set = IpRangeSet.from_cidrs([ "2001:db8::/32" ])

    assert set.include?("2001:db8::1")
    assert_not set.include?("32.1.13.184") # 2001:0db8 と同じ整数値の IPv4
  end

  test "IPv4射影アドレスはIPv4として判定すること" do
    set = IpRangeSet.from_cidrs([ "192.0.2.0/24" ])

    assert set.include?("::ffff:192.0.2.1")
  end

  test "書き出した内容を読み込むと同じ判定になること" do
    set = IpRangeSet.from_cidrs([ "192.0.2.0/24", "2001:db8::/32" ])

    Tempfile.create("ip_ranges") do |file|
      file.write(set.to_lines.join("\n"))
      file.flush
      loaded = IpRangeSet.load(file.path)

      assert_equal set.size, loaded.size
      assert loaded.include?("192.0.2.10")
      assert loaded.include?("2001:db8::10")
      assert_not loaded.include?("198.51.100.1")
    end
  end
end
