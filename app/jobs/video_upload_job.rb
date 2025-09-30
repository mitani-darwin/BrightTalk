class VideoUploadJob < ApplicationJob
  queue_as :default

  def perform(video_attachment)
    unless video_attachment&.persisted?
      Rails.logger.info "Video attachment no longer exists, skipping job"
      return
    end

    unless video_attachment.blob&.persisted?
      Rails.logger.info "Video blob no longer exists, skipping job"
      return
    end

    return unless video_attachment.blob&.content_type&.start_with?("video/")
    return if video_attachment.blob.metadata["async_upload_completed"] == true

    begin
      # S3での存在確認と整合性チェック
      if video_attachment.blob.service.respond_to?(:exist?) &&
         video_attachment.blob.service.exist?(video_attachment.blob.key)

        # ファイルサイズの整合性チェック（オプション）
        begin
          # より安全なファイルサイズ取得方法
          actual_size = video_attachment.blob.service.service.head_object(
            bucket: video_attachment.blob.service.bucket.name,
            key: video_attachment.blob.key
          ).content_length
          expected_size = video_attachment.blob.byte_size

          if actual_size != expected_size
            Rails.logger.warn "File size mismatch for #{video_attachment.blob.filename}: expected #{expected_size}, got #{actual_size}"
          end
        rescue => size_check_error
          Rails.logger.warn "Could not verify file size: #{size_check_error.message}"
        end

        # メタデータ更新
        video_attachment.blob.update!(
          metadata: video_attachment.blob.metadata.merge(
            "async_upload_completed" => true,
            "uploaded_by" => "video_upload_job",
            "verified_at" => Time.current.iso8601
          )
        )
        Rails.logger.info "VideoUploadJob completed successfully for: #{video_attachment.blob.filename}"
      else
        Rails.logger.error "Video file not found in S3: #{video_attachment.blob.filename}"
        # 必要に応じて再アップロードロジックをここに追加
      end
    rescue ActiveRecord::RecordNotFound => e
      Rails.logger.info "Video attachment or blob was deleted before job execution: #{e.message}"
    rescue => e
      Rails.logger.error "Error processing video upload job: #{e.message}"
      raise # エラーを再発生させて再試行可能にする
    end
  end

  rescue_from ActiveJob::DeserializationError do |exception|
    Rails.logger.info "Video attachment was deleted before job execution: #{exception.message}"
  end
end