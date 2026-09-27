# コメント投稿元 IP の判定に使う IP 範囲リスト（IpRangeUpdater が生成）を読み込む
# ファイルが差し替えられたら（mtime が変わったら）自動で読み込み直す
class IpRangeDatabase
  LISTS = { japan: "japan.txt", hosting: "hosting.txt" }.freeze

  @sets = {}
  @mutex = Mutex.new

  class << self
    # テスト用: ファイルの代わりに使う IpRangeSet（{ japan:, hosting: }）
    attr_accessor :override

    def directory
      Pathname(ENV.fetch("IP_RANGES_DIR", Rails.root.join("storage/ip_ranges")))
    end

    def path_for(list)
      directory.join(LISTS.fetch(list))
    end

    # 日本に割り当てられた IP 範囲
    def japan
      set(:japan)
    end

    # クラウド・ホスティング事業者の IP 範囲
    def hosting
      set(:hosting)
    end

    private

    # ファイルが無い・壊れている場合は nil を返す
    def set(list)
      return override[list] if override

      path = path_for(list)
      return nil unless path.exist?

      mtime = path.mtime
      @mutex.synchronize do
        cached = @sets[list]
        return cached[:set] if cached && cached[:mtime] == mtime

        set = IpRangeSet.load(path)
        @sets[list] = { set: set, mtime: mtime }
        set
      end
    rescue ArgumentError, SystemCallError => e
      Rails.logger.error("[IpRangeDatabase] #{list} の読み込みに失敗しました: #{e.class}: #{e.message}")
      nil
    end
  end
end
