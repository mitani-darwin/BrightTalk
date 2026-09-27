namespace :storage do
  desc "Active Storage（S3）と DB の食い違いを棚卸しする（読み取り専用）。OLDER_THAN_HOURS=48 DETAILS=1 で調整"
  task audit: :environment do
    hours = Integer(ENV.fetch("OLDER_THAN_HOURS", "48"))
    ActiveRecord::Base.logger = nil # SQL ログがレポートに混ざらないようにする
    StorageAudit.new(older_than: hours.hours.ago).print_report(details: ENV["DETAILS"].present?)
  end
end
