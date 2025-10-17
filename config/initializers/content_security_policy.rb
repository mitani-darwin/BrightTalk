# config/initializers/content_security_policy.rb
Rails.application.configure do
  # すべての環境で CSP の nonce を有効化（script と style の両方）
  config.content_security_policy_nonce_generator = ->(_request) { SecureRandom.base64(16) }
  config.content_security_policy_nonce_directives = %w[script-src style-src]

  if Rails.env.development?
    # 開発環境: HMR などローカルへの接続を許可
    localhost_http = %w[http://localhost:3036 http://127.0.0.1:3036]
    localhost_ws   = %w[ws://localhost:3036 ws://127.0.0.1:3036]

    config.content_security_policy do |policy|
      policy.script_src  :self, :https, *localhost_http, :unsafe_eval
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
    # 本番/その他環境: CDN と自己ドメインのみ許可。インラインは nonce によって許可される。
    config.content_security_policy do |policy|
      policy.default_src :self
      policy.script_src  :self, :https
      policy.style_src   :self, :https, "https://cdn.jsdelivr.net", "https://cdnjs.cloudflare.com"
      policy.img_src     :self, :https, :data
      policy.font_src    :self, :https, :data, "https://cdn.jsdelivr.net", "https://cdnjs.cloudflare.com"
      policy.connect_src :self, :https
    end
  end
end