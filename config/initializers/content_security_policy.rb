# config/initializers/content_security_policy.rb
Rails.application.configure do
  # 必ず config. を付ける
  config.content_security_policy do |policy|
    policy.default_src :self

    # 画像/フォント（dataやblobも許可）
    policy.img_src  :self, :https, :data, :blob
    policy.font_src :self, :https,
                    'https://cdn.jsdelivr.net',
                    'https://cdnjs.cloudflare.com',
                    :data

    # スタイル（外部CSSはホスト許可。インライン<style>は nonce/attr で許可）
    policy.style_src :self, :https,
                     'https://cdn.jsdelivr.net',
                     'https://cdnjs.cloudflare.com'

    # インライン style 属性の許可（RailsのDSLにある場合は属性限定、なければ暫定で全体許可）
    if policy.respond_to?(:style_src_attr)
      policy.style_src_attr :unsafe_inline
    else
      policy.style_src :self, :https,
                       'https://cdn.jsdelivr.net',
                       'https://cdnjs.cloudflare.com',
                       :unsafe_inline
    end

    # 開発時は Vite HMR 用の緩和（eval と WS 接続の許可）
    if Rails.env.development?
      policy.script_src  :self, :https, :unsafe_eval
      policy.connect_src :self, :https, 'http://localhost:3036', 'ws://localhost:3036'
    else
      policy.script_src  :self, :https
      policy.connect_src :self, :https
    end

    # 外部スクリプトCDN（必要に応じて）
    policy.script_src  :self, :https,
                       'https://cdn.jsdelivr.net',
                       'https://cdnjs.cloudflare.com',
                       'https://www.googletagmanager.com',
                       'https://www.google-analytics.com'

    policy.frame_ancestors :self
  end

  # ここを追加: 各リクエストで nonce を必ず生成
  config.content_security_policy_nonce_generator = -> request { SecureRandom.base64(16) }
  # 生成した nonce をどのディレクティブに適用するか
  config.content_security_policy_nonce_directives = %w(script-src style-src)

  # 必要に応じてレポートオンリー
  # config.content_security_policy_report_only = true
end