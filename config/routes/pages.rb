# config/routes/pages.rb
Rails.application.routes.draw do
  # 静的ページのルーティング
  # Static pages routing

  get "privacy-policy", to: "pages#privacy_policy", as: "privacy_policy"
  get "terms-of-service", to: "pages#terms_of_service", as: "terms_of_service"
  get "markdown-guide", to: "pages#markdown_guide", as: "markdown_guide"
end
