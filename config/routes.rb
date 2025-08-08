Rails.application.routes.draw do
  devise_for :users, controllers: {
    registrations: "users/registrations",
    sessions: "sessions",
    confirmations: "users/confirmations"
  }

  # ユーザー登録成功ページのルートを追加
  devise_scope :user do
    get "users/registration/success", to: "users/registrations#success", as: "users_registration_success"
    # check_webauthnルートをdevise_scope内に移動
    post "check_webauthn", to: "sessions#check_webauthn"
    # WebAuthnログイン用のルート追加も同様に移動
    get "login", to: "sessions#check_webauthn"
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

  resources :webauthn_credentials, except: [ :edit, :update ]
  resources :webauthn_authentications, only: [ :new, :create ] do
    collection do
      post :check_login_method  # 新しいアクション
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