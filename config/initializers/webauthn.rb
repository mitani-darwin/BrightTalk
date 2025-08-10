WebAuthn.configure do |config|
  # ⭐ 新しいAPIを使用: allowed_origins
  config.allowed_origins = if Rails.env.development?
                             ["http://localhost:3000", "http://127.0.0.1:3000"]
                           else
                             ["https://www.brighttalk.jp"]
                           end

  # Relying Party ID (ドメイン)
  config.rp_id = Rails.env.development? ? "localhost" : "www.brighttalk.jp"

  # Relying Party の名前 (ユーザーに表示される)
  config.rp_name = "BrightTalk"

  # ⭐ 認証情報のタイムアウト（ミリ秒）- 新しいAPIを使用
  config.credential_options_timeout = 120_000

  # ⭐ authentication_timeout は削除（存在しない設定）
end