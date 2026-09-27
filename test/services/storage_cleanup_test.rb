require "test_helper"

class StorageCleanupTest < ActiveSupport::TestCase
  setup do
    @service = ActiveStorage::Blob.service
    @io = StringIO.new
    @paths = []
  end

  teardown do
    @paths.each { |path| FileUtils.rm_f(path) }
  end

  def cleanup
    StorageCleanup.new(audit: StorageAudit.new(service: @service, older_than: 1.minute.from_now), service: @service, io: @io)
  end

  def create_blob(filename)
    ActiveStorage::Blob.create_and_upload!(io: StringIO.new("data"), filename: filename, content_type: "image/png")
  end

  def write_file(key)
    path = @service.path_for(key)
    FileUtils.mkdir_p(File.dirname(path))
    File.write(path, "orphan")
    @paths << path
    path
  end

  test "CONFIRMなしでは何も削除しないこと" do
    blob = create_blob("unattached.png")
    orphan_path = write_file(SecureRandom.base36(28))

    assert_no_difference("ActiveStorage::Blob.count") { cleanup.call }

    assert @service.exist?(blob.key)
    assert File.exist?(orphan_path)
    assert_match "CONFIRM=yes", @io.string
  end

  test "添付されていないファイルとDBに記録が無いファイルを削除すること" do
    unattached = create_blob("unattached.png")
    orphan_path = write_file(SecureRandom.base36(28))

    cleanup.call(execute: true)

    assert_not ActiveStorage::Blob.exists?(unattached.id)
    assert_not @service.exist?(unattached.key)
    assert_not File.exist?(orphan_path)
  end

  test "添付済みのファイルとActive Storage以外の形式のファイルは削除しないこと" do
    attached = create_blob("attached.png")
    users(:test_user).avatar.attach(attached)
    other_path = write_file("backup-2026-09-27.sql.gz")

    cleanup.call(execute: true)

    assert ActiveStorage::Blob.exists?(attached.id)
    assert @service.exist?(attached.key)
    assert File.exist?(other_path)
  end

  test "棚卸し後に添付されたファイルは削除しないこと" do
    blob = create_blob("late.png")
    audit = StorageAudit.new(service: @service, older_than: 1.minute.from_now)
    audit.unattached_blobs # 棚卸し時点では添付なし
    users(:test_user).avatar.attach(blob)

    blob_result, = StorageCleanup.new(audit: audit, service: @service, io: @io).call(execute: true)

    assert ActiveStorage::Blob.exists?(blob.id)
    assert_operator blob_result.skipped, :>=, 1
  end
end
