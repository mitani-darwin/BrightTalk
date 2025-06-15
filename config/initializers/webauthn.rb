WebAuthn.configure do |config|
  # アプリケーションの許可されたオリジン（複数設定可能）
  config.allowed_origins = if Rails.env.development?
                             ["http://localhost:3000"]
                           else
                             ["https://yourdomain.com"] # 本番環境のドメインに変更
                           end

  # Relying Party (RP) の識別子
  config.rp_id = if Rails.env.development?
                   "localhost"
                 else
                   "yourdomain.com" # 本番環境のドメインに変更
                 end

  # Relying Party の名前
  config.rp_name = "BrightTalk"

  # 認証器の要件
  config.credential_options_timeout = 120_000 # 2分
end