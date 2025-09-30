# Be sure to restart your server when you modify this file.

# Version of your assets, change this if you want to expire all your assets.
Rails.application.config.assets.version = "1.1"

# Add additional assets to the asset load path.
# Rails.application.config.assets.paths << Emoji.images_path

# CDNライブラリをプリコンパイル対象から除外
Rails.application.config.assets.precompile = [
  # デフォルトのアプリケーションファイル
  "application.js",
  "application.css",
  "application.scss",

  # ローカルのStimulusファイルのみ
  "stimulus-loading.js",
  /controllers\/.*\.js$/,

  # ローカルモジュール
  "passkey.js"
]
