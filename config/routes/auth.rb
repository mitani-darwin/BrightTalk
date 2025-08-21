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

  # パスキー認証ルーティング
  resources :passkey_authentications, only: [:new, :create] do
    collection do
      post :auth_options
    end
  end

  # POST /passkeys を受けるルート（エラー解消のため）
  devise_scope :user do
    post '/passkeys', to: 'devise/passkeys#create'
  end

end