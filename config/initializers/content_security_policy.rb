# config/initializers/content_security_policy.rb
Rails.application.configure do
  if Rails.env.development?
    # スタイルは inline 許可、スクリプトは nonce を使う
    config.content_security_policy_nonce_generator = ->(_request) { SecureRandom.base64(16) }
    config.content_security_policy_nonce_directives = %w[script-src] # ← style-src は含めない

    localhost_http = %w[http://localhost:3036 http://127.0.0.1:3036]
    localhost_ws   = %w[ws://localhost:3036 ws://127.0.0.1:3036]

    config.content_security_policy do |policy|
      policy.script_src  :self, :https, *localhost_http, :unsafe_eval
      policy.style_src   :self, :https, *localhost_http, :unsafe_inline,
                         "https://cdn.jsdelivr.net", "https://cdnjs.cloudflare.com"
      policy.font_src    :self, :https, :data,
                         "https://cdn.jsdelivr.net", "https://cdnjs.cloudflare.com"
      policy.img_src     :self, :https, :data, *localhost_http
      policy.connect_src :self, :https, *localhost_http, *localhost_ws
    end
  else
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