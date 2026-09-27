# Active Storage のストレージ（本番は S3）と DB の食い違いを棚卸しする
# 読み取り専用で、ファイルも DB も一切変更しない（bin/rails storage:audit から実行）
class StorageAudit
  # Active Storage が生成するキーの形式（SecureRandom.base36(28)）
  BLOB_KEY_FORMAT = /\A[0-9a-z]{28}\z/
  DETAIL_LIMIT_WITHOUT_DETAILS = 20

  StoredObject = Data.define(:key, :byte_size, :last_modified)

  # older_than より新しいものは、アップロード中・保存前の可能性があるため対象外にする
  def initialize(service: ActiveStorage::Blob.service, older_than: 48.hours.ago)
    @service = service
    @older_than = older_than
  end

  # DB にはあるが、どのレコードにも添付されていない blob（例: 動画を選んだまま投稿を保存しなかった）
  def unattached_blobs
    @unattached_blobs ||= blobs.unattached.where(created_at: ...@older_than).order(:created_at).to_a
  end

  # ストレージにはあるが DB に blob が無いファイル
  def orphaned_objects
    @orphaned_objects ||= stored_objects.select { |object| object.last_modified < @older_than && !blob_keys.include?(object.key) }
  end

  # 上のうち Active Storage のキー形式のもの（削除候補）
  def orphaned_blob_objects
    orphaned_objects.select { |object| object.key.match?(BLOB_KEY_FORMAT) }
  end

  # 上のうち Active Storage 以外の形式のもの（別用途の可能性があるため削除候補にしない）
  def orphaned_other_objects
    orphaned_objects.reject { |object| object.key.match?(BLOB_KEY_FORMAT) }
  end

  # DB に blob はあるがストレージに実体が無いもの（表示できない壊れた添付）
  def missing_blobs
    @missing_blobs ||= begin
      blobs.where(created_at: ...@older_than).includes(:attachments).reject { |blob| stored_keys.include?(blob.key) }
    end
  end

  def print_report(io = $stdout, details: false)
    io.puts "=== Active Storage 棚卸し（読み取り専用。何も削除しません）==="
    io.puts "ストレージ: #{@service.name}#{" (バケット: #{@service.bucket.name})" if @service.respond_to?(:bucket)}"
    io.puts "対象: #{@older_than.in_time_zone.strftime("%Y-%m-%d %H:%M")} より前に作成されたもの"
    io.puts "ストレージ上のファイル総数: #{stored_objects.size} 件（#{human_size(stored_objects.sum(&:byte_size))}）"
    io.puts "DB の blob 総数: #{blob_keys.size} 件"

    section(io, "1. どこにも添付されていないファイル【削除候補】", unattached_blobs, details) do |blob|
      "#{blob.key}  #{human_size(blob.byte_size).rjust(10)}  #{blob.created_at.strftime("%Y-%m-%d %H:%M")}  #{blob.content_type}  #{blob.filename}"
    end
    present = unattached_blobs.select { |blob| stored_keys.include?(blob.key) }
    io.puts "  → うちストレージに実体があるもの（削除で実際に減る量）: #{present.size} 件（#{human_size(present.sum(&:byte_size))}）"
    section(io, "2. DB に記録が無いファイル（Active Storage 形式）【削除候補】", orphaned_blob_objects, details) do |object|
      object_line(object)
    end
    # 別用途のファイルが混ざっていないか目視で確認できるよう、DETAILS が無くても一覧を出す
    section(io, "3. DB に記録が無いファイル（Active Storage 以外の形式）【対象外・要確認】", orphaned_other_objects, true) do |object|
      object_line(object)
    end
    section(io, "4. DB にあるがストレージに実体が無い blob【壊れた添付・要確認】", missing_blobs, details) do |blob|
      records = blob.attachments.map { |a| "#{a.record_type}##{a.record_id}(#{a.name})" }.presence&.join(", ") || "添付なし"
      "#{blob.key}  #{blob.created_at.strftime("%Y-%m-%d %H:%M")}  #{blob.filename}  → #{records}"
    end
  end

  private

  def blobs
    ActiveStorage::Blob.where(service_name: @service.name)
  end

  def blob_keys
    @blob_keys ||= blobs.pluck(:key).to_set
  end

  def stored_keys
    @stored_keys ||= stored_objects.map(&:key).to_set
  end

  def stored_objects
    @stored_objects ||=
      if @service.respond_to?(:bucket) # S3
        @service.bucket.objects.map { |object| StoredObject.new(object.key, object.size, object.last_modified) }
      elsif @service.respond_to?(:root) # Disk（開発・テスト）
        Dir.glob(File.join(@service.root, "**", "*")).select { |path| File.file?(path) }.map do |path|
          StoredObject.new(File.basename(path), File.size(path), File.mtime(path))
        end
      else
        raise ArgumentError, "未対応のストレージです: #{@service.class}"
      end
  end

  def section(io, title, items, details)
    total = items.sum { |item| item.respond_to?(:byte_size) ? item.byte_size.to_i : 0 }
    io.puts
    io.puts "#{title}: #{items.size} 件（#{human_size(total)}）"
    shown = details ? items : items.first(DETAIL_LIMIT_WITHOUT_DETAILS)
    shown.each { |item| io.puts "  #{yield(item)}" }
    if shown.size < items.size
      io.puts "  …ほか #{items.size - shown.size} 件（全件は DETAILS=1 を付けて実行）"
    end
  end

  def object_line(object)
    "#{object.key}  #{human_size(object.byte_size).rjust(10)}  #{object.last_modified.in_time_zone.strftime("%Y-%m-%d %H:%M")}"
  end

  def human_size(bytes)
    ActiveSupport::NumberHelper.number_to_human_size(bytes)
  end
end
