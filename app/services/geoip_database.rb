require "maxmind/db"

# GeoLite2（MaxMind）の mmdb ファイルを読み込む
# ファイルが差し替えられたら（mtime が変わったら）自動で読み込み直す
class GeoipDatabase
  EDITIONS = { country: "GeoLite2-Country", asn: "GeoLite2-ASN" }.freeze

  @readers = {}
  @mutex = Mutex.new

  class << self
    # テスト用: 実ファイルの代わりに使う reader（#get(ip) に応答するオブジェクト）
    attr_accessor :override

    def directory
      Pathname(ENV.fetch("GEOIP_DB_DIR", Rails.root.join("storage/geoip")))
    end

    def path_for(edition)
      directory.join("#{EDITIONS.fetch(edition)}.mmdb")
    end

    def country
      reader(:country)
    end

    def asn
      reader(:asn)
    end

    private

    # ファイルが無い・壊れている場合は nil を返す
    def reader(edition)
      return override[edition] if override

      path = path_for(edition)
      return nil unless path.exist?

      mtime = path.mtime
      @mutex.synchronize do
        cached = @readers[edition]
        return cached[:reader] if cached && cached[:mtime] == mtime

        reader = MaxMind::DB.new(path.to_s, mode: MaxMind::DB::MODE_MEMORY)
        @readers[edition] = { reader: reader, mtime: mtime }
        reader
      end
    rescue MaxMind::DB::InvalidDatabaseError, SystemCallError => e
      Rails.logger.error("[GeoipDatabase] #{edition} の読み込みに失敗しました: #{e.class}: #{e.message}")
      nil
    end
  end
end
