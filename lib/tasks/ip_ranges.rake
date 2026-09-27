namespace :ip_ranges do
  desc "日本の IP 範囲（APNIC）とクラウド・ホスティング事業者の IP 範囲を取得して更新する"
  task update: :environment do
    IpRangeUpdater.new.call
    puts "IP 範囲リストを #{IpRangeDatabase.directory} に更新しました"
  end
end
