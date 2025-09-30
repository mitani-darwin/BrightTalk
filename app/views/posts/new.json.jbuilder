json.extract! @post, :id, :title, :content, :purpose, :target_audience, :created_at, :updated_at
json.url post_url(@post, format: :json)