WebAuthn.configure do |config|
  # 非推奨のWebAuthn.originの代わりにallowed_originsを使用
  config.allowed_origins = case Rails.env
                           when 'production'
                             ['https://www.brighttalk.jp']
                           when 'development'
                             ['http://localhost:3000']
                           when 'test'
                             ['http://test.host']
                           else
                             ['http://localhost:3000']
                           end

  # Relying Party（RP）の設定
  config.rp_name = "BrightTalk"

  # 本番環境とその他の環境でRP IDを設定
  config.origin = nil
  config.rp_id = case Rails.env
                 when 'production'
                   'www.brighttalk.jp'
                 else
                   'localhost'
                 end

  # 認証子の選択設定
  config.credential_options_timeout = 60_000

  # 認証の有効期限（秒）
  config.credential_options_timeout = 120_000

  # セキュリティ設定
  config.verify_attestation_statement = Rails.env.production?
  config.acceptable_attestation_types = ['none', 'self', 'basic']

  # アルゴリズム設定（ES256, RS256をサポート）
  config.algorithms = ['ES256', 'RS256']
end