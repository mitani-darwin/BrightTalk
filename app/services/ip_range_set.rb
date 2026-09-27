require "ipaddr"

# IP アドレス範囲の集合
# 範囲を整数に変換して結合・ソートしておき、二分探索で含まれるかを判定する
class IpRangeSet
  FAMILIES = [ Socket::AF_INET, Socket::AF_INET6 ].freeze

  # "1.0.16.0/20" 形式の CIDR の配列から作る
  def self.from_cidrs(cidrs)
    new(cidrs.map { |cidr| cidr_range(cidr) })
  end

  # to_lines で書き出したファイル（1行に「先頭IP 末尾IP」）から読み込む
  def self.load(path)
    new(File.foreach(path).filter_map do |line|
      first, last = line.split
      [ IPAddr.new(first), IPAddr.new(last) ] if first && last
    end)
  end

  def self.cidr_range(cidr)
    range = IPAddr.new(cidr.strip).to_range
    [ range.begin, range.end ]
  end

  # ranges: [先頭IP, 末尾IP]（IPAddr）の配列
  def initialize(ranges)
    grouped = FAMILIES.index_with { [] }
    ranges.each do |first, last|
      grouped.fetch(first.family) << [ first.to_i, last.to_i ]
    end
    @ranges = grouped.transform_values { |list| merge(list.sort) }
  end

  def include?(ip)
    address = ip.is_a?(IPAddr) ? ip : IPAddr.new(ip)
    address = address.native # IPv4 射影アドレス（::ffff:x.x.x.x）は IPv4 として扱う
    value = address.to_i
    range = @ranges.fetch(address.family).bsearch { |_first, last| last >= value }
    range.present? && range.first <= value
  end

  def size
    @ranges.values.sum(&:size)
  end

  def to_lines
    @ranges.flat_map do |family, list|
      list.map { |first, last| "#{IPAddr.new(first, family)} #{IPAddr.new(last, family)}" }
    end
  end

  private

  # 重なり・隣接する範囲を結合する（結合後は末尾も昇順になり二分探索できる）
  def merge(sorted)
    sorted.each_with_object([]) do |(first, last), merged|
      if merged.any? && first <= merged.last[1] + 1
        merged.last[1] = [ merged.last[1], last ].max
      else
        merged << [ first, last ]
      end
    end
  end
end
