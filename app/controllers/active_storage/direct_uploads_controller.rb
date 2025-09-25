class ActiveStorage::DirectUploadsController < ActiveStorage::BaseController
  skip_before_action :verify_authenticity_token  # コメントアウトを解除

  def create
    # Rails 8対応：キーワード引数を使用
    blob_params = blob_args
    blob = ActiveStorage::Blob.create_before_direct_upload!(
      filename: blob_params[:filename],
      byte_size: blob_params[:byte_size],
      checksum: blob_params[:checksum],
      content_type: blob_params[:content_type],
      metadata: blob_params[:metadata] || {},
      service_name: ActiveStorage::Blob.service.name
    )

    render json: direct_upload_json(blob)
  rescue ActiveStorage::IntegrityError
    render json: { error: "Integrity check failed" }, status: :unprocessable_entity
  rescue => e
    Rails.logger.error "DirectUpload error: #{e.message}"
    Rails.logger.error e.backtrace.join("\n")
    render json: { error: "Upload failed: #{e.message}" }, status: :bad_request
  end

  private

  def blob_args
    params.require(:blob).permit(:filename, :byte_size, :checksum, :content_type, metadata: {})
  end

  def direct_upload_json(blob)
    {
      signed_id: blob.signed_id,
      direct_upload: {
        url: blob.service_url_for_direct_upload,
        headers: blob.service_headers_for_direct_upload
      }
    }
  end
end