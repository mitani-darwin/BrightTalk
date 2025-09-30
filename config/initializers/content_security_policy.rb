Rails.application.configure do
  config.content_security_policy do |policy|
    policy.default_src :self, :https
    policy.font_src    :self, :https, :data
    policy.img_src     :self, :https, :data
    policy.object_src  :none
    policy.script_src  :self, :https, :unsafe_inline, :unsafe_eval, :blob
    policy.style_src   :self, :https, :unsafe_inline

    # WebAuthn用のCSSPディレクティブを追加
    if Rails.env.development?
      policy.script_src :self, :https, :unsafe_inline, :unsafe_eval
      policy.connect_src :self, :https, "ws://localhost:*", "http://localhost:*"
    end
  end
end
