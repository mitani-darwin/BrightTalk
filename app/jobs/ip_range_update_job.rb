# コメント投稿元 IP の判定に使う IP 範囲リストの定期更新（config/recurring.yml から実行）
class IpRangeUpdateJob < ApplicationJob
  queue_as :default

  def perform
    IpRangeUpdater.new.call
  end
end
