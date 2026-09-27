require "net/http"

# 公開データから IP 範囲リストを取得して storage/ip_ranges に書き出す
# - 日本の IP 範囲: APNIC の割り当て統計（delegated-apnic-latest）
# - クラウド・ホスティング事業者の IP 範囲: config/hosting_ip_ranges.yml の各事業者の公開一覧
# どれか1つでも取得・解析に失敗したら例外にし、既存のファイルはそのまま残す
class IpRangeUpdater
  APNIC_URL = "https://ftp.apnic.net/stats/apnic/delegated-apnic-latest"
  HOSTING_CONFIG_PATH = Rails.root.join("config/hosting_ip_ranges.yml")
  # 取得失敗や形式変更で極端に少ないリストに差し替えないための下限
  MIN_JAPAN_RANGES = 1_000
  MAX_REDIRECTS = 3

  # APNIC の統計ファイルから日本（JP）に割り当て済みの範囲を取り出す
  # 行の形式: apnic|JP|ipv4|1.0.16.0|4096|20110412|allocated（ipv4 はアドレス数、ipv6 はプレフィックス長）
  def self.parse_apnic(body)
    body.each_line.filter_map do |line|
      _registry, country, type, start, value, _date, status = line.strip.split("|")
      next unless country == "JP" && %w[allocated assigned].include?(status)

      case type
      when "ipv4"
        first = IPAddr.new(start)
        [ first, IPAddr.new(first.to_i + value.to_i - 1, Socket::AF_INET) ]
      when "ipv6"
        IpRangeSet.cidr_range("#{start}/#{value}")
      end
    end
  end

  # 事業者ごとの公開一覧から CIDR の配列を取り出す
  def self.parse_hosting_source(format, body)
    case format
    when "aws"
      json = JSON.parse(body)
      json.fetch("prefixes").map { |p| p.fetch("ip_prefix") } +
        json.fetch("ipv6_prefixes").map { |p| p.fetch("ipv6_prefix") }
    when "google_cloud"
      JSON.parse(body).fetch("prefixes").map { |p| p["ipv4Prefix"] || p.fetch("ipv6Prefix") }
    when "oracle"
      JSON.parse(body).fetch("regions").flat_map do |region|
        (region.fetch("cidrs") + region.fetch("ipv6_cidrs", [])).map { |c| c.fetch("cidr") }
      end
    when "geofeed" # RFC 8805 の CSV（1列目が CIDR）
      body.each_line.filter_map do |line|
        line = line.strip
        line.split(",").first.strip unless line.empty? || line.start_with?("#")
      end
    when "text" # 1行に1つの CIDR
      body.each_line.map(&:strip).reject(&:empty?)
    else
      raise ArgumentError, "未対応の形式です: #{format}"
    end
  end

  def call
    japan = IpRangeSet.new(self.class.parse_apnic(fetch(URI(APNIC_URL))))
    if japan.size < MIN_JAPAN_RANGES
      raise "APNIC から取得した日本の IP 範囲が少なすぎます（#{japan.size} 件）"
    end

    hosting = IpRangeSet.from_cidrs(hosting_cidrs)

    FileUtils.mkdir_p(IpRangeDatabase.directory)
    write(:japan, japan)
    write(:hosting, hosting)
  end

  private

  def hosting_cidrs
    config = YAML.load_file(HOSTING_CONFIG_PATH)
    cidrs = config.fetch("sources").flat_map do |source|
      list = self.class.parse_hosting_source(source.fetch("format"), fetch(URI(source.fetch("url"))))
      raise "#{source.fetch("name")}: IP 範囲を取得できませんでした" if list.empty?

      list
    end
    cidrs + Array(config["extra_cidrs"])
  end

  def write(list, set)
    destination = IpRangeDatabase.path_for(list)
    tmp_path = Pathname("#{destination}.tmp")
    File.write(tmp_path, set.to_lines.join("\n") + "\n")
    File.rename(tmp_path, destination)
    Rails.logger.info("[IpRangeUpdater] #{destination.basename} を更新しました（#{set.size} 範囲）")
  ensure
    FileUtils.rm_f(tmp_path) if tmp_path
  end

  def fetch(uri, redirects_left = MAX_REDIRECTS)
    response = Net::HTTP.start(uri.host, uri.port, use_ssl: uri.scheme == "https", open_timeout: 10, read_timeout: 120) do |http|
      http.request(Net::HTTP::Get.new(uri))
    end

    case response
    when Net::HTTPSuccess
      response.body
    when Net::HTTPRedirection
      raise "#{uri}: リダイレクトが多すぎます" if redirects_left.zero?
      fetch(URI.join(uri, response["location"]), redirects_left - 1)
    else
      raise "#{uri}: 取得に失敗しました (HTTP #{response.code})"
    end
  end
end
