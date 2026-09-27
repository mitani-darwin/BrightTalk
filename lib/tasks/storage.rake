namespace :storage do
  desc "Active Storage（S3）と DB の食い違いを棚卸しする（読み取り専用）。OLDER_THAN_HOURS=48 DETAILS=1 で調整"
  task audit: :environment do
    hours = Integer(ENV.fetch("OLDER_THAN_HOURS", "48"))
    ActiveRecord::Base.logger = nil # SQL ログがレポートに混ざらないようにする
    StorageAudit.new(older_than: hours.hours.ago).print_report(details: ENV["DETAILS"].present?)
  end

  desc "storage:audit の削除候補（1: 添付されていないファイル、2: DB に記録が無いファイル）を削除する。CONFIRM=yes で実行"
  task cleanup: :environment do
    hours = Integer(ENV.fetch("OLDER_THAN_HOURS", "48"))
    ActiveRecord::Base.logger = nil # SQL ログが出力に混ざらないようにする
    audit = StorageAudit.new(older_than: hours.hours.ago)
    StorageCleanup.new(audit: audit).call(execute: ENV["CONFIRM"] == "yes")
  end
end
