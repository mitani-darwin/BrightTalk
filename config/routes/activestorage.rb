# ActiveStorageの設定
Rails.application.routes.draw do
  # ActiveStorageの標準ルートを明示的に定義
  scope "/rails/active_storage" do
    # Direct Uploadエンドポイント
    post "/direct_uploads", to: "active_storage/direct_uploads#create", as: :rails_direct_uploads

    # Blob配信エンドポイント
    get "/blobs/redirect/:signed_id/*filename", to: "active_storage/blobs/redirect#show", as: :rails_service_blob
    get "/blobs/proxy/:signed_id/*filename", to: "active_storage/blobs/proxy#show", as: :rails_blob_proxy

    # Representation配信エンドポイント
    get "/representations/redirect/:signed_id/:variation_key/*filename", to: "active_storage/representations/redirect#show", as: :rails_blob_representation
    get "/representations/proxy/:signed_id/:variation_key/*filename", to: "active_storage/representations/proxy#show", as: :rails_blob_representation_proxy
  end

  # Direct helperも保持
  direct :rails_blob_path do |blob, **options|
    ActiveStorage::Current.url_options = options
    route_for(:rails_service_blob, blob.signed_id, blob.filename, **options)
  end
end
