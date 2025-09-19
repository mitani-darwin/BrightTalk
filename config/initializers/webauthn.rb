# config/initializers/webauthn.rb

WebAuthn.configure do |config|
  # 本番環境とローカル環境でoriginを切り替え
  config.allowed_origins = if Rails.env.development?
                             [
                               "http://localhost:3000"
                             ]
  else
                             [ "https://www.brighttalk.jp" ]
  end

  # Relying Party ID（ドメイン名）
  config.rp_id = if Rails.env.development?
                   "localhost"
  else
                   "www.brighttalk.jp"
  end

  # Relying Party 名前
  config.rp_name = "BrightTalk"

  # アルゴリズム設定
  config.algorithms = [ "ES256", "PS256", "RS256" ]

  # タイムアウト設定（ミリ秒）
  config.credential_options_timeout = 300_000

  # レスポンスタイムアウト（秒）
  # config.silent_authentication_timeout = 300

  # 受け入れ可能な認証タイプ（修正済み）
  config.acceptable_attestation_types = [ "none", "self", "indirect", "direct" ]

  # 証明書検証を無効化（追加）
  config.verify_attestation_statement = false
end
