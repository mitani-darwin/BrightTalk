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

gem "solid_cache"
gem "solid_queue"
gem "solid_cable"
gem "bcrypt", "~> 3.1.7"
gem "kaminari"
gem "dartsass-rails"

gem "devise"
gem "devise-i18n"

# ⭐ devise-passkeys gem と webauthn gem
gem "devise-passkeys", "~> 0.3.0"
gem "webauthn", "~> 3.1"

gem "mini_magick"
gem "active_storage_validations"
gem 'grover'
gem 'mail-ses'

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