require "net/http"
require "rubygems/package"
require "zlib"

# MaxMind から GeoLite2 データベースをダウンロードして差し替える
# 環境変数 MAXMIND_ACCOUNT_ID / MAXMIND_LICENSE_KEY が必要
class GeoipDatabaseUpdater
  DOWNLOAD_URL = "https://download.maxmind.com/geoip/databases/%s/download?suffix=tar.gz"
  MAX_REDIRECTS = 3

  def initialize(account_id: ENV["MAXMIND_ACCOUNT_ID"], license_key: ENV["MAXMIND_LICENSE_KEY"])
    @account_id = account_id
    @license_key = license_key
  end

  def call
    if @account_id.blank? || @license_key.blank?
      raise ArgumentError, "MAXMIND_ACCOUNT_ID と MAXMIND_LICENSE_KEY を設定してください"
    end

    FileUtils.mkdir_p(GeoipDatabase.directory)
    GeoipDatabase::EDITIONS.each_key { |edition| update(edition) }
  end

  private

  def update(edition)
    name = GeoipDatabase::EDITIONS.fetch(edition)
    mmdb = extract_mmdb(download(URI(format(DOWNLOAD_URL, name))), name)

    destination = GeoipDatabase.path_for(edition)
    tmp_path = Pathname("#{destination}.tmp")
    File.binwrite(tmp_path, mmdb)
    # 壊れたファイルで差し替えないよう、読み込めることを確認してから置き換える
    MaxMind::DB.new(tmp_path.to_s, mode: MaxMind::DB::MODE_MEMORY)
    File.rename(tmp_path, destination)
    Rails.logger.info("[GeoipDatabaseUpdater] #{name} を更新しました")
  ensure
    FileUtils.rm_f(tmp_path) if tmp_path
  end

  def download(uri, redirects_left = MAX_REDIRECTS)
    request = Net::HTTP::Get.new(uri)
    # 認証情報は MaxMind 本体にのみ送る（リダイレクト先のストレージには送らない）
    request.basic_auth(@account_id, @license_key) if uri.host == "download.maxmind.com"

    response = Net::HTTP.start(uri.host, uri.port, use_ssl: true, open_timeout: 10, read_timeout: 120) do |http|
      http.request(request)
    end

    case response
    when Net::HTTPSuccess
      response.body
    when Net::HTTPRedirection
      raise "#{uri.host}: リダイレクトが多すぎます" if redirects_left.zero?
      download(URI(response["location"]), redirects_left - 1)
    else
      raise "#{uri.host}: ダウンロードに失敗しました (HTTP #{response.code})"
    end
  end

  def extract_mmdb(archive, name)
    Gem::Package::TarReader.new(Zlib::GzipReader.new(StringIO.new(archive))) do |tar|
      tar.each do |entry|
        return entry.read if entry.file? && File.basename(entry.full_name) == "#{name}.mmdb"
      end
    end
    raise "#{name}.mmdb がアーカイブ内に見つかりません"
  end
end
