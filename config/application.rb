require_relative "boot"

# Selectively require Rails components (exclude unused ones)
require "rails"
require "active_model/railtie"
require "active_job/railtie"
require "active_record/railtie"
require "active_storage/engine"
require "action_controller/railtie"
require "action_mailer/railtie"
require "action_mailbox/engine"
require "action_view/railtie"
require "action_cable/engine"  # Disabled - not used
require "action_text/engine"   # Disabled - not used
require "rails/test_unit/railtie"

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(*Rails.groups)

module BrightTalk
  class Application < Rails::Application
    # Initialize configuration defaults for originally generated Rails version.
    config.load_defaults 8.0
    # config/application.rb
    config.assets.paths << Rails.root.join("app/assets/stylesheets")

    # Please, add to the `ignore` list any other `lib` subdirectories that do
    # not contain `.rb` files, or that should not be reloaded or eager loaded.
    # Common ones are `templates`, `generators`, or `middleware`, for example.
    config.autoload_lib(ignore: %w[assets tasks])

    # Configuration for the application, engines, and railties goes here.
    #
    # These settings can be overridden in specific environments using the files
    # in config/environments/, which are processed later.
    #
    # config.time_zone = "Central Time (US & Canada)"
    # config.eager_load_paths << Rails.root.join("extras")

    # 日本語設定
    config.time_zone = "Tokyo"
    config.i18n.default_locale = :ja
    config.i18n.available_locales = [ :ja, :en ]

    # 画像のEXIF削除対応 - VIPS利用可能時のみ設定
    begin
      require "ruby-vips"
      config.active_storage.variant_processor = :vips
    rescue LoadError
      Rails.logger.warn "ruby-vips not available, using default image processor"
      config.active_storage.variant_processor = :mini_magick
    end
  end
end
