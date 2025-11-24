# config/initializers/content_security_policy.rb
Rails.application.configure do
  # すべての環境でnonceを無効化（:unsafe_inlineを使用）
  config.content_security_policy_nonce_generator = nil
  config.content_security_policy_nonce_directives = []

  if Rails.env.development?
    # 開発環境: HMR などローカルへの接続を許可
    localhost_http = %w[http://localhost:3036 http://127.0.0.1:3036]
    localhost_ws   = %w[ws://localhost:3036 ws://127.0.0.1:3036]

    config.content_security_policy do |policy|
      # Development environment needs :unsafe_inline for inline scripts and styles
      policy.script_src  :self, :https, *localhost_http, :unsafe_eval, :unsafe_inline
      # Development environment needs :unsafe_inline for Vite HMR, Turbo, and Video.js
      policy.style_src   :self, :https, *localhost_http,
                         "https://cdn.jsdelivr.net", "https://cdnjs.cloudflare.com", :unsafe_inline
      # Explicitly allow element styles for some browsers during dev HMR
      policy.style_src_elem :self, :https, *localhost_http,
                            "https://cdn.jsdelivr.net", "https://cdnjs.cloudflare.com", :unsafe_inline
      policy.font_src    :self, :https, :data,
                         "https://cdn.jsdelivr.net", "https://cdnjs.cloudflare.com"
      policy.img_src     :self, :https, :data, *localhost_http
      policy.connect_src :self, :https, *localhost_http, *localhost_ws
    end
  else
    # 本番/その他環境: CDN と自己ドメインのみ許可。インラインは :unsafe_inline によって許可される。
    config.content_security_policy do |policy|
      s3_bucket   = "https://brighttalk-prod-image-production.s3.ap-northeast-1.amazonaws.com"
      s3_wild     = "https://*.s3.ap-northeast-1.amazonaws.com"
      amazon_wild = "https://*.amazonaws.com"

      policy.default_src :self, :https, s3_bucket, s3_wild, amazon_wild, :data, :blob
      policy.script_src  :self, :https, :unsafe_inline
      policy.style_src   :self, :https, "https://cdn.jsdelivr.net", "https://cdnjs.cloudflare.com", :unsafe_inline
      policy.style_src_elem :self, :https, "https://cdn.jsdelivr.net", "https://cdnjs.cloudflare.com", :unsafe_inline
      policy.img_src     :self, :https, :data, :blob, s3_bucket, s3_wild, amazon_wild
      policy.media_src   :self, :https, :data, :blob, s3_bucket, s3_wild, amazon_wild
      policy.font_src    :self, :https, :data, "https://cdn.jsdelivr.net", "https://cdnjs.cloudflare.com"
      policy.connect_src :self, :https, s3_bucket, s3_wild, amazon_wild
    end
  end
end
