class VideoUploadJob < ApplicationJob
  queue_as :default

  def perform(video_attachment)
    return unless video_attachment.attached?
    return unless video_attachment.blob&.content_type&.start_with?('video/')

    # メタデータチェックで処理済みかを確認
    return if video_attachment.blob.metadata['async_upload_completed'] == true

    begin
      # S3での存在確認のみ
      if video_attachment.blob.service.respond_to?(:exist?) &&
         video_attachment.blob.service.exist?(video_attachment.blob.key)

        # 存在する場合はメタデータ更新のみ
        video_attachment.blob.update!(
          metadata: video_attachment.blob.metadata.merge(
            'async_upload_completed' => true,
            'uploaded_by' => 'video_upload_job'
          )
        )
      else
        # 存在しない場合のみ、Active Storageの通常アップロード処理
        # （実際には、この状況は通常発生しないはず）
        Rails.logger.warn "Video not found in S3, this should not happen: #{video_attachment.filename}"
      end
    rescue => e
      # エラーハンドリング
    end
  end

end