WebAuthn.configure do |config|
  # 新しい書式でoriginを設定
  if Rails.env.production?
    # 本番環境：複数のoriginを許可する新しい書式
    config.allowed_origins = [
      "https://www.brighttalk.jp",
      "https://brighttalk.jp"  # www無しも許可（必要に応じて）
    ]
    config.rp_id = "www.brighttalk.jp"
  else
    # 開発環境
    config.allowed_origins = [
      "http://localhost:3000",
      "http://127.0.0.1:3000"
    ]
    config.rp_id = "localhost"
  end

  # RP名の設定
  config.rp_name = "BrightTalk"

  # タイムアウト設定
  config.credential_options_timeout = 120_000

  # 本番環境でのログ出力
  config.logger = Rails.logger if Rails.env.production?

  # アルゴリズムの設定（必要に応じて）
  config.algorithms = ["ES256", "PS256", "RS256"]
end