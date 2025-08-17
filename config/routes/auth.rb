# 認証関連のルーティング
Rails.application.routes.draw do
  # Deviseルーティング
  devise_for :users, controllers: {
    registrations: 'users/registrations',
    confirmations: 'users/confirmations'
  }
  
  # パスキー登録ルーティング
  resources :passkey_registrations, only: [:new, :create] do
    collection do
      post :register_passkey
      post :verify_passkey
    end
  end
end