
Rails.application.routes.draw do
  # ホームページ
  root "posts#index"

  # devise_for :users（カスタムconfirmationsコントローラーを使用）
  devise_for :users, controllers: {
    confirmations: 'users/confirmations'
  }, skip: [:sessions, :passwords, :registrations]

  # WebAuthn認証
  get '/login', to: 'webauthn_authentications#new'
  resources :webauthn_credentials, except: [:edit, :update]
  resources :webauthn_authentications, only: [:new, :create]

  # 新規登録（名前付きルートを追加）
  get '/users/sign_up', to: 'users#new', as: 'new_user_registration'
  post '/users', to: 'users#create'

  # 仮登録完了ページ
  get '/users/registration_pending', to: 'users#registration_pending', as: 'registration_pending_users'

  # ログアウト
  devise_scope :user do
    delete '/logout', to: 'devise/sessions#destroy', as: :destroy_user_session
  end

  # ユーザー関連
  resources :users, only: [:show]
  get 'users/:id/posts', to:'posts#user_posts', as: 'user_posts'

  # 投稿関連
  resources :posts do
    resources :likes, only: [:index, :create, :destroy]
    resources :comments, only: [:create, :destroy]
  end

  # ヘルスチェック
  get "up" => "rails/health#show", as: :rails_health_check
end