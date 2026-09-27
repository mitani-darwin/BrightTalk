# どこにも添付されないまま一定時間経ったファイル（投稿を保存しなかった動画など）を削除する
# config/recurring.yml から毎日実行
class PurgeUnattachedBlobsJob < ApplicationJob
  queue_as :default

  # アップロード中・保存前のファイルを消さないよう、作成から十分経ったものだけを対象にする
  OLDER_THAN = 2.days

  def perform
    ActiveStorage::Blob.unattached.where(created_at: ...OLDER_THAN.ago).find_each(&:purge_later)
  end
end
