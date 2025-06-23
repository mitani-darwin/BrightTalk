
Rails.application.routes.draw do
  devise_for :users, controllers: {
    registrations: "users/registrations",
    sessions: "sessions",
    confirmations: "users/confirmations"
  }

  root "posts#index"

  # check_webauthnルートを追加
  post "check_webauthn", to: "sessions#check_webauthn"

  resources :posts do
    member do
      patch :publish
    end
    collection do
      get :drafts
    end
    resources :comments, only: [ :create, :destroy ]
    resources :likes, only: [ :create, :destroy ]
  end

  resources :webauthn_credentials, except: [ :edit, :update ]
  resources :webauthn_authentications, only: [ :new, :create ] do
    collection do
      get :login
      post :password_login
    end
  end

  # ユーザー関連のルート
  get "/users/:id", to: "users#show", as: "user"
  get "/users/:id/posts", to: "posts#user_posts", as: "user_posts"
  get "/account", to: "users#account", as: "user_account"
  get "/account/edit", to: "users#edit_account", as: "edit_user_account"
  patch "/account", to: "users#update_account"
  get "/account/password/edit", to: "users#edit_password", as: "edit_account_password"
  patch "/account/password", to: "users#update_password", as: "update_account_password"

  # ヘルスチェック
  get "up" => "rails/health#show", as: :rails_health_check
  get "service-worker" => "rails/pwa#service_worker", as: :pwa_service_worker
  get "manifest" => "rails/pwa#manifest", as: :pwa_manifest
end