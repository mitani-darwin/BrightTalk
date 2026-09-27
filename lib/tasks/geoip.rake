namespace :geoip do
  desc "GeoLite2（国・ASN）データベースを MaxMind からダウンロードして更新する"
  task update: :environment do
    GeoipDatabaseUpdater.new.call
    puts "GeoLite2 データベースを #{GeoipDatabase.directory} に更新しました"
  end
end
