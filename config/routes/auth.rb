# 認証関連のルーティング
Rails.application.routes.draw do
  # Deviseルーティング
  devise_for :users, controllers: {
    registrations: 'users/registrations',
    confirmations: 'users/confirmations'
  }
end