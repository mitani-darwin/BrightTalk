# GeoLite2 データベースの定期更新（config/recurring.yml から実行）
class GeoipUpdateJob < ApplicationJob
  queue_as :default

  def perform
    GeoipDatabaseUpdater.new.call
  end
end
