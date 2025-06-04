class ApplicationController < ActionController::Base
  include SessionsHelper

  # Only allow modern browsers supporting webp images, web push, badges, import maps, CSS nesting, and CSS :has.
  allow_browser versions: :modern

  # CSRF protection (Rails 8では自動的に有効になっています)
  protect_from_forgery with: :exception

end
