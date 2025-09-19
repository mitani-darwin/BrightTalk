class RemoveExifJob < ApplicationJob
  queue_as :default

  def perform(image_attachment)
    return unless image_attachment.attached?
    return unless image_attachment.content_type&.start_with?("image/")
    return unless defined?(MiniMagick)

    Rails.logger.info "Starting EXIF removal for: #{image_attachment.filename}"

    begin
      # S3から画像データをダウンロード
      image_data = image_attachment.download

      # EXIF情報があるかチェック
      has_exif = image_data.include?("Exif")

      if !has_exif
        Rails.logger.info "No EXIF data found in: #{image_attachment.filename}"
        return
      end

      Rails.logger.info "EXIF data found, removing from: #{image_attachment.filename}"

      # 一時ファイルに保存してMiniMagickで処理
      Tempfile.open([ "exif_removal", File.extname(image_attachment.filename.to_s) ]) do |temp_file|
        temp_file.binmode
        temp_file.write(image_data)
        temp_file.rewind

        # MiniMagickで画像を処理してEXIF削除
        processed_image = MiniMagick::Image.open(temp_file.path)

        # EXIF情報を削除
        processed_image.strip

        # 処理済み画像を新しい一時ファイルに保存
        Tempfile.open([ "processed_exif", File.extname(image_attachment.filename.to_s) ]) do |processed_file|
          processed_file.binmode
          processed_image.write(processed_file.path)
          processed_file.rewind

          # 元の画像を処理済み画像で置き換え
          image_attachment.blob.update!(
            checksum: Digest::MD5.file(processed_file.path).base64digest,
            byte_size: processed_file.size
          )

          # S3の元ファイルを処理済みファイルで置き換え
          service = ActiveStorage::Blob.service
          service.upload(
            image_attachment.blob.key,
            processed_file,
            checksum: image_attachment.blob.checksum,
            content_type: image_attachment.content_type
          )

          Rails.logger.info "EXIF removal completed for: #{image_attachment.filename}"
        end
      end

    rescue => e
      Rails.logger.error "EXIF removal failed for #{image_attachment.filename}: #{e.message}"
      Rails.logger.error "Stack trace: #{e.backtrace.first(5).join("\n")}"
      # エラーが発生してもジョブは正常終了（画像は使用可能）
    end
  end
end
