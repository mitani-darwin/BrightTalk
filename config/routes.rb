Rails.application.routes.draw do
  devise_for :users, controllers: {
    registrations: "users/registrations",
    sessions: "sessions",
    confirmations: "users/confirmations"
  }

  # Passkeys の新しいルート
  resources :passkeys, only: [:index, :new, :create, :destroy]

  # Passkey認証ルート
  resource :passkey_authentication, only: [:new, :create] do
    member do
      post :check_login_method    # ← member に変更
      post :password_login
    end
  end

  devise_scope :user do
    get "users/registration/success", to: "users/registrations#success", as: "users_registration_success"
    get "users/registration/pending", to: "users#registration_pending", as: "registration_pending_users"
  end

  resources :categories, only: [:create, :index]
  root "posts#index"

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