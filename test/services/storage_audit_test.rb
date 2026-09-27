require "test_helper"

class StorageAuditTest < ActiveSupport::TestCase
  setup do
    @service = ActiveStorage::Blob.service
    @audit_time = 1.minute.from_now
  end

  def audit
    StorageAudit.new(service: @service, older_than: @audit_time)
  end

  def create_blob(filename)
    ActiveStorage::Blob.create_and_upload!(io: StringIO.new("data"), filename: filename, content_type: "image/png")
  end

  def write_file(key)
    path = @service.path_for(key)
    FileUtils.mkdir_p(File.dirname(path))
    File.write(path, "orphan")
    path
  end

  test "添付されていないblobだけを削除候補にすること" do
    unattached = create_blob("unattached.png")
    attached = create_blob("attached.png")
    users(:test_user).avatar.attach(attached)

    keys = audit.unattached_blobs.map(&:key)

    assert_includes keys, unattached.key
    assert_not_includes keys, attached.key
  end

  test "指定時刻より新しいblobは対象外にすること" do
    blob = create_blob("new.png")

    result = StorageAudit.new(service: @service, older_than: 1.hour.ago).unattached_blobs

    assert_not_includes result.map(&:key), blob.key
  end

  test "DBに記録が無いファイルをキー形式で分けて検出すること" do
    blob = create_blob("known.png")
    orphan_key = SecureRandom.base36(28)
    other_key = "backup-2026-09-27.sql.gz"
    paths = [ write_file(orphan_key), write_file(other_key) ]

    result = audit

    assert_includes result.orphaned_blob_objects.map(&:key), orphan_key
    assert_not_includes result.orphaned_blob_objects.map(&:key), other_key
    assert_includes result.orphaned_other_objects.map(&:key), other_key
    assert_not_includes result.orphaned_objects.map(&:key), blob.key
  ensure
    paths&.each { |path| FileUtils.rm_f(path) }
  end

  test "ストレージに実体が無いblobを検出すること" do
    blob = create_blob("missing.png")
    FileUtils.rm_f(@service.path_for(blob.key))

    assert_includes audit.missing_blobs.map(&:key), blob.key
  end

  test "レポートを出力してもファイルとDBを変更しないこと" do
    blob = create_blob("keep.png")
    orphan_key = SecureRandom.base36(28)
    path = write_file(orphan_key)
    io = StringIO.new

    assert_no_difference("ActiveStorage::Blob.count") do
      audit.print_report(io, details: true)
    end

    assert File.exist?(path)
    assert @service.exist?(blob.key)
    assert_match "読み取り専用", io.string
    assert_match blob.key, io.string
    assert_match orphan_key, io.string
  ensure
    FileUtils.rm_f(path) if path
  end
end
