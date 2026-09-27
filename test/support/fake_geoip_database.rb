# GeoLite2 の reader と同じく #get(ip) でレコードを返す偽のデータベース
class FakeGeoipDatabase
  def initialize(records)
    @records = records
  end

  def get(ip)
    IPAddr.new(ip) # 不正な IP は実物と同じく例外にする
    @records[ip]
  end

  # 203.0.113.1: 国内の一般回線 / .2: 国外 / .3: 国内のクラウド事業者
  # .4: 組織名に VPN を含む国内 ASN / .5: 国内だが ASN 未登録
  COUNTRY = new({
    "203.0.113.1" => { "country" => { "iso_code" => "JP" } },
    "203.0.113.2" => { "country" => { "iso_code" => "US" } },
    "203.0.113.3" => { "country" => { "iso_code" => "JP" } },
    "203.0.113.4" => { "country" => { "iso_code" => "JP" } },
    "203.0.113.5" => { "country" => { "iso_code" => "JP" } }
  })
  ASN = new({
    "203.0.113.1" => { "autonomous_system_number" => 2516, "autonomous_system_organization" => "KDDI CORPORATION" },
    "203.0.113.3" => { "autonomous_system_number" => 16509, "autonomous_system_organization" => "AMAZON-02" },
    "203.0.113.4" => { "autonomous_system_number" => 64500, "autonomous_system_organization" => "Example VPN Service" }
  })
end
