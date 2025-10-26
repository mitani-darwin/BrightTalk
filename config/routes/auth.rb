# 認証関連のルーティング
Rails.application.routes.draw do
  # Deviseルーティング（Rails 8.2 以降のキーワード引数仕様に対応）
  devise_for :users,
             skip: [ :sessions, :registrations, :confirmations ],
             controllers: {
               sessions: "users/sessions",
               registrations: "users/registrations",
               confirmations: "users/confirmations"
             }

  devise_scope :user do
    # Sessions
    get "users/sign_in", to: "users/sessions#new", as: :new_user_session
    post "users/sign_in", to: "users/sessions#create", as: :user_session
    delete "users/sign_out", to: "users/sessions#destroy", as: :destroy_user_session

    # Registrations
    get "users/sign_up", to: "users/registrations#new", as: :new_user_registration
    get "users/edit", to: "users/registrations#edit", as: :edit_user_registration
    post "users", to: "users/registrations#create", as: :user_registration
    match "users", to: "users/registrations#update", via: [ :patch, :put ]
    delete "users", to: "users/registrations#destroy", as: :destroy_user_registration
    get "users/cancel", to: "users/registrations#cancel", as: :cancel_user_registration

    # Confirmations
    get "users/confirmation/new", to: "users/confirmations#new", as: :new_user_confirmation
    get "users/confirmation", to: "users/confirmations#show", as: :user_confirmation
    post "users/confirmation", to: "users/confirmations#create"
  end

  # パスキー登録ルーティング
  resources :passkey_registrations, only: [ :new, :create ] do
    collection do
      post :register_passkey
      post :verify_passkey
    end
  end

  # パスキー認証ルーティング
  resources :passkey_authentications, only: [ :new, :create ] do
    collection do
      post :auth_options
    end
  end

  # POST /passkeys を受けるルート（エラー解消のため）
  # パスキー管理ルーティング
  devise_scope :user do
    resources :passkeys, only: [ :index, :create, :destroy ], controller: "devise/passkeys"
  end
end
