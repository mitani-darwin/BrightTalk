require "test_helper"

class PurgeUnattachedBlobsJobTest < ActiveJob::TestCase
  def create_blob(filename, created_at:)
    blob = ActiveStorage::Blob.create_and_upload!(io: StringIO.new("data"), filename: filename, content_type: "image/png")
    blob.update_column(:created_at, created_at)
    blob
  end

  test "2日以上前の添付されていないファイルだけを削除すること" do
    old_unattached = create_blob("old.png", created_at: 3.days.ago)
    new_unattached = create_blob("new.png", created_at: 1.hour.ago)
    old_attached = create_blob("attached.png", created_at: 3.days.ago)
    users(:test_user).avatar.attach(old_attached)

    perform_enqueued_jobs { PurgeUnattachedBlobsJob.perform_now }

    assert_not ActiveStorage::Blob.exists?(old_unattached.id)
    assert ActiveStorage::Blob.exists?(new_unattached.id)
    assert ActiveStorage::Blob.exists?(old_attached.id)
  end
end
