
WebAuthn.configure do |config|
  # 本番環境のオリジン設定
  config.origin = "https://www.brighttalk.jp"

  # RP ID（Relying Party ID）の設定
  config.rp_id = "www.brighttalk.jp"

  # 本番環境用の設定
  if Rails.env.production?
    config.origin = "https://www.brighttalk.jp"
    config.rp_id = "www.brighttalk.jp"
  elsif Rails.env.development?
    config.origin = "http://localhost:3000"
    config.rp_id = "localhost"
  end
end