# コメント投稿元 IP の制限
# 日本に割り当てられた IP かつ、クラウド・ホスティング事業者（VPN・プロキシの出口）以外からの投稿のみ許可する
# 判定できない場合（IP 範囲リストが無い、IP が不正等）は拒否する
class CommentIpRestriction
  # check の戻り値: :allowed / :foreign（国外）/ :hosting（VPN・データセンター）/ :unavailable（判定不可）
  def self.enabled?
    Rails.configuration.x.comment_ip_restriction_enabled
  end

  def initialize(japan: IpRangeDatabase.japan, hosting: IpRangeDatabase.hosting)
    @japan = japan
    @hosting = hosting
  end

  def check(ip)
    return :unavailable if @japan.nil? || @hosting.nil?

    address = IPAddr.new(ip)
    # クラウド事業者の IP は米国等の登録でも国内リージョンで使われるため、国より先に判定する
    return :hosting if @hosting.include?(address)
    return :foreign unless @japan.include?(address)

    :allowed
  rescue ArgumentError => e
    Rails.logger.warn("[CommentIpRestriction] #{ip} を判定できませんでした: #{e.class}: #{e.message}")
    :unavailable
  end
end
