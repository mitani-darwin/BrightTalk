# コメント投稿元 IP の制限
# 日本国内の IP かつ、クラウド・ホスティング事業者（VPN・プロキシの出口）以外からの投稿のみ許可する
# 判定できない場合（GeoIP データベースが無い、IP が登録されていない等）は拒否する
class CommentIpRestriction
  ALLOWED_COUNTRY = "JP"
  HOSTING_CONFIG_PATH = Rails.root.join("config/hosting_asns.yml")

  # check の戻り値: :allowed / :foreign（国外）/ :hosting（VPN・データセンター）/ :unavailable（判定不可）
  def self.enabled?
    Rails.configuration.x.comment_ip_restriction_enabled
  end

  def self.hosting_config
    @hosting_config ||= YAML.load_file(HOSTING_CONFIG_PATH).freeze
  end

  def initialize(country_db: GeoipDatabase.country, asn_db: GeoipDatabase.asn)
    @country_db = country_db
    @asn_db = asn_db
    @hosting_asns = self.class.hosting_config.fetch("asns").to_set
    @hosting_keywords = self.class.hosting_config.fetch("organization_keywords").map(&:downcase)
  end

  def check(ip)
    return :unavailable if @country_db.nil? || @asn_db.nil?

    country = @country_db.get(ip)&.dig("country", "iso_code")
    return :unavailable if country.nil?
    return :foreign unless country == ALLOWED_COUNTRY

    asn = @asn_db.get(ip)
    return :unavailable if asn.nil?
    return :hosting if hosting?(asn)

    :allowed
  rescue ArgumentError, MaxMind::DB::InvalidDatabaseError => e
    Rails.logger.warn("[CommentIpRestriction] #{ip} を判定できませんでした: #{e.class}: #{e.message}")
    :unavailable
  end

  private

  def hosting?(asn)
    organization = asn["autonomous_system_organization"].to_s.downcase
    @hosting_asns.include?(asn["autonomous_system_number"]) ||
      @hosting_keywords.any? { |keyword| organization.include?(keyword) }
  end
end
