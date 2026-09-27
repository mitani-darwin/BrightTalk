# StorageAudit の削除候補を削除する（bin/rails storage:cleanup から実行）
# - どこにも添付されていない blob（DB の記録とストレージのファイル）
# - DB に記録が無い Active Storage 形式のファイル
# Active Storage 以外の形式のファイルは別用途の可能性があるため削除しない
class StorageCleanup
  Result = Data.define(:deleted, :skipped, :failed)

  def initialize(audit: StorageAudit.new, service: ActiveStorage::Blob.service, io: $stdout)
    @audit = audit
    @service = service
    @io = io
  end

  # execute: false のときは件数を表示するだけで何も削除しない
  def call(execute: false)
    blobs = @audit.unattached_blobs
    objects = @audit.orphaned_blob_objects

    @io.puts "削除対象: どこにも添付されていないファイル #{blobs.size} 件 / DB に記録が無いファイル #{objects.size} 件（#{human_size(objects.sum(&:byte_size))}）"
    unless execute
      @io.puts "確認のみで終了しました。削除するには CONFIRM=yes を付けて実行してください。"
      return
    end

    blob_result = purge_blobs(blobs)
    object_result = delete_objects(objects)
    @io.puts "添付されていないファイル: 削除 #{blob_result.deleted} 件 / スキップ #{blob_result.skipped} 件 / 失敗 #{blob_result.failed} 件"
    @io.puts "DB に記録が無いファイル: 削除 #{object_result.deleted} 件 / スキップ #{object_result.skipped} 件 / 失敗 #{object_result.failed} 件"
    [ blob_result, object_result ]
  end

  private

  def purge_blobs(blobs)
    each_with_result(blobs) do |blob|
      # 棚卸し後に添付された場合は削除しない
      next :skipped if blob.attachments.exists?

      blob.purge
      :deleted
    end
  end

  def delete_objects(objects)
    each_with_result(objects) do |object|
      # 棚卸し後に DB に記録された場合は削除しない
      next :skipped if ActiveStorage::Blob.exists?(key: object.key)

      @service.delete(object.key)
      :deleted
    end
  end

  def each_with_result(items)
    counts = { deleted: 0, skipped: 0, failed: 0 }
    items.each_with_index do |item, index|
      counts[yield(item)] += 1
    rescue => e
      counts[:failed] += 1
      @io.puts "  失敗: #{item.key}: #{e.class}: #{e.message}"
    ensure
      @io.puts "  #{index + 1}/#{items.size} 件処理" if ((index + 1) % 100).zero?
    end
    Result.new(**counts)
  end

  def human_size(bytes)
    ActiveSupport::NumberHelper.number_to_human_size(bytes)
  end
end
