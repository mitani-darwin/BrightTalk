
# 開発環境でのみパラメータフィルタリングを無効化
if Rails.env.development?
  Rails.application.config.filter_parameters = []
end