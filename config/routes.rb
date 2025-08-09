Rails.application.routes.draw do
  devise_for :users, controllers: {
    registrations: "users/registrations",
    sessions: "sessions",
    confirmations: "users/confirmations"
  }

  # Devise Passkeys ルート
  devise_scope :user do
    # Passkey 管理
    resources :passkeys, controller: 'devise/passkeys', as: 'user_passkeys', path: 'users/passkeys'

    # Passkey認証セッション
    resource :passkey_session, controller: 'devise/passkey_sessions', as: 'user_passkey_session', path: 'users/passkey_session' do
      collection do
        post :challenge
      end
    end

    # その他のdevise関連ルート
    get "users/registration/success", to: "users/registrations#success", as: "users_registration_success"
    get "users/registration/pending", to: "users#registration_pending", as: "registration_pending_users"
  end

  # 残りのルートは既存のまま...
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

  get "/users/:id", to: "users#show", as: "user"
  get "/users/:id/posts", to: "posts#user_posts", as: "user_posts"
  get "/account", to: "users#account", as: "user_account"
  get "/account/edit", to: "users#edit_account", as: "edit_user_account"
  patch "/account", to: "users#update_account"
  get "/account/password/edit", to: "users#edit_password", as: "edit_account_password"
  patch "/account/password", to: "users#update_password", as: "update_account_password"

  get "up" => "rails/health#show", as: :rails_health_check
  get "service-worker" => "rails/pwa#service_worker", as: :pwa_service_worker
  get "manifest" => "rails/pwa#manifest", as: :pwa_manifest
end