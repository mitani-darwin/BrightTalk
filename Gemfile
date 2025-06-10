
source "https://rubygems.org"

gem "rails", "~> 8.0.2"
gem "propshaft"
gem "puma", ">= 5.0"
gem "importmap-rails"
gem "turbo-rails"
gem "stimulus-rails"
gem "jbuilder"
gem "bootsnap", require: false
gem "kamal", require: false
gem "thruster", require: false
gem "image_processing", "~> 1.2"

# Railsのセキュリティ機能に必要
gem "solid_cache"
gem "solid_queue"
gem "solid_cable"

# パスワードハッシュ化のため
gem "bcrypt", "~> 3.1.7"

# ページネーション
gem "kaminari"

# Sassプリプロセッサ
gem "dartsass-rails"

gem 'devise'
# Deviseの日本語化
gem 'devise-i18n'

# 画像処理
gem 'mini_magick'

# Active Storage バリデーション
gem 'active_storage_validations'

# PDF生成
gem 'wicked_pdf'
gem 'wkhtmltopdf-binary'

group :development, :test do
  gem "debug", platforms: %i[ mri windows ], require: "debug/prelude"
  gem "brakeman", require: false
  gem "rubocop-rails-omakase", require: false
end

group :development do
  gem "web-console"
end

group :test do
  gem "capybara"
  gem "selenium-webdriver"
end

group :production do
  gem "sqlite3", ">= 2.1"
end