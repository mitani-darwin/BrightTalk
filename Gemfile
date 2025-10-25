source "https://rubygems.org"

gem "rails", "~> 8.1.0"
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

gem "devise"
# Deviseの日本語化
gem "devise-i18n"

# WebAuthn/Passkey認証
gem "webauthn", "~> 3.4"

# 画像処理 - オプショナル（システムにVIPSがインストールされていない場合はスキップ）
gem "ruby-vips", require: false

# EXIF data manipulation
gem "exifr"

# Active Storage バリデーション
gem "active_storage_validations"

# Markdown処理
gem "redcarpet"

# URL slug generation
gem "friendly_id"

# Sitemap generation
gem "sitemap_generator"

# PDF生成
gem "grover" # ChromeベースのPDF生成

gem "mail-ses"

gem "aws-sdk-s3", require: false

gem 'uglifier'

# CORS support for S3 direct uploads
gem "rack-cors"

group :development, :test do
  gem "debug", platforms: %i[ mri windows ], require: "debug/prelude"
  gem "brakeman", require: false
  gem "rubocop-rails-omakase", require: false
end

group :development do
  gem "web-console"
  gem "foreman"
end

group :test do
  gem "capybara"
  gem "selenium-webdriver"
end

group :production do
  gem "sqlite3", ">= 2.1"
end

gem "vite_rails", github: "ElMassimo/vite_ruby", branch: "main"