# config/routes/pages.rb
Rails.application.routes.draw do
  # 静的ページのルーティング
  # Static pages routing
  
  get 'privacy-policy', to: 'pages#privacy_policy', as: 'privacy_policy'
end