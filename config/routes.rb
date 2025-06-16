Rails.application.routes.draw do
  # ホームページ
  root "posts#index"

  # devise_for :users（カスタムcontrollersを使用）
  devise_for :users, controllers: {
    confirmations: 'users/confirmations',
    sessions: 'sessions'
  }, skip: [:passwords, :registrations]

  # WebAuthn認証
  get '/login', to: 'webauthn_authentications#new'
  resources :webauthn_credentials, except: [:edit, :update]
  resources :webauthn_authentications, only: [:new, :create]

  # 新規登録（名前付きルートを追加）
  get '/users/sign_up', to: 'users#new', as: 'new_user_registration'
  post '/users', to: 'users#create'

  # 仮登録完了ページ
  get '/users/registration_pending', to: 'users#registration_pending', as: 'registration_pending_users'

  # ユーザー管理画面
  get '/account', to: 'users#account', as: 'user_account'
  get '/account/edit', to: 'users#edit_account', as: 'edit_user_account'
  patch '/account', to: 'users#update_account'
  put '/account', to: 'users#update_account'

  # パスワード変更（正しい名前付きルート）
  get '/account/password', to: 'users#edit_password', as: 'edit_user_password'
  patch '/account/password', to: 'users#update_password', as: 'update_user_password'
  put '/account/password', to: 'users#update_password'

  # ログアウト（GETとDELETEの両方をサポート）
  devise_scope :user do
    get '/users/sign_out', to: 'devise/sessions#destroy'
    delete '/users/sign_out', to: 'devise/sessions#destroy'
    get '/logout', to: 'devise/sessions#destroy'
  end

  # ユーザー関連（sign_outをshowアクションから除外）
  resources :users, only: [:show], constraints: { id: /\d+/ }
  get 'users/:id/posts', to:'posts#user_posts', as: 'user_posts'

  # 投稿関連
  resources :posts do
    resources :likes, only: [:index, :create, :destroy]
    resources :comments, only: [:create, :destroy]
  end

  # ヘルスチェック
  get "up" => "rails/health#show", as: :rails_health_check
end