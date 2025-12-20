module Tailwind
  class BaseController < ApplicationController
    layout "tailwind"

    # Tailwind専用のビューを優先し、Bootstrap領域への混入を防ぐ
    prepend_view_path Rails.root.join("app/views/tw")
  end
end
