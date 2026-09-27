require "test_helper"

class IpRangeUpdaterTest < ActiveSupport::TestCase
  test "APNICの統計から日本に割り当て済みの範囲だけを取り出すこと" do
    body = <<~APNIC
      2|apnic|20260927|70000|19830613|20260926|+1000
      apnic|*|ipv4|*|40000|summary
      apnic|JP|ipv4|1.0.16.0|4096|20110412|allocated
      apnic|JP|ipv4|1.1.64.0|768|20110412|assigned
      apnic|CN|ipv4|1.0.1.0|256|20110414|allocated
      apnic|JP|ipv4|1.0.0.0|256|20110412|reserved
      apnic|JP|ipv6|2001:200::|35|19990813|allocated
      apnic|JP|asn|2497|1|19930901|allocated
    APNIC

    set = IpRangeSet.new(IpRangeUpdater.parse_apnic(body))

    assert set.include?("1.0.16.0")
    assert set.include?("1.0.31.255")
    assert_not set.include?("1.0.32.0")
    assert set.include?("1.1.66.255") # 768 アドレス（2のべき乗でない）の末尾
    assert_not set.include?("1.1.67.0")
    assert_not set.include?("1.0.1.1")   # CN
    assert_not set.include?("1.0.0.1")   # reserved
    assert set.include?("2001:200:1fff::1")
    assert_not set.include?("2001:200:2000::1")
  end

  test "AWSの公開一覧からCIDRを取り出すこと" do
    body = { prefixes: [ { ip_prefix: "3.4.12.4/32" } ], ipv6_prefixes: [ { ipv6_prefix: "2406:daba:f000::/40" } ] }.to_json

    assert_equal [ "3.4.12.4/32", "2406:daba:f000::/40" ], IpRangeUpdater.parse_hosting_source("aws", body)
  end

  test "Google Cloudの公開一覧からCIDRを取り出すこと" do
    body = { prefixes: [ { ipv4Prefix: "34.1.208.0/20" }, { ipv6Prefix: "2600:1900:4000::/44" } ] }.to_json

    assert_equal [ "34.1.208.0/20", "2600:1900:4000::/44" ], IpRangeUpdater.parse_hosting_source("google_cloud", body)
  end

  test "Oracle Cloudの公開一覧からCIDRを取り出すこと" do
    body = { regions: [ { region: "ap-tokyo-1", cidrs: [ { cidr: "40.233.0.0/19" } ], ipv6_cidrs: [ { cidr: "2603:c020::/32" } ] } ] }.to_json

    assert_equal [ "40.233.0.0/19", "2603:c020::/32" ], IpRangeUpdater.parse_hosting_source("oracle", body)
  end

  test "geofeed形式からコメント行を除いてCIDRを取り出すこと" do
    body = <<~CSV
      # ip_prefix, alpha2code, region, city, postal_code
      5.101.96.0/21,NL,NL-NH,Amsterdam,1098 XH

      2600:3c00::/32,US,US-TX,Richardson,
    CSV

    assert_equal [ "5.101.96.0/21", "2600:3c00::/32" ], IpRangeUpdater.parse_hosting_source("geofeed", body)
  end

  test "text形式から空行を除いてCIDRを取り出すこと" do
    assert_equal [ "173.245.48.0/20", "2400:cb00::/32" ],
                 IpRangeUpdater.parse_hosting_source("text", "173.245.48.0/20\n\n2400:cb00::/32\n")
  end

  test "hosting_ip_ranges.ymlの形式がすべて解析に対応していること" do
    config = YAML.load_file(IpRangeUpdater::HOSTING_CONFIG_PATH)

    config.fetch("sources").each do |source|
      assert_includes %w[aws google_cloud oracle geofeed text], source.fetch("format"), source["name"]
    end
    config.fetch("extra_cidrs").each { |cidr| IpRangeSet.cidr_range(cidr) }
  end
end
