Rails.application.routes.draw do
  # devise_for :users
  devise_for :users, controllers: {
    registrations: 'users/registrations',
    confirmations: 'users/confirmations'
  }

  # 新規登録成功ページのルートを追加
  devise_scope :user do
    get '/users/registration/success', to: 'users/registrations#success', as: :success_users_registration
  end


  # ホームページ
  root "posts#index"

  # ユーザー関連（showのみ残す）
  resources :users, only: [:show]

  # 既存のルートに追加
  get 'users/:id/posts', to: 'posts#user_posts', as: 'user_posts'

  # 投稿関連
  resources :posts do
    resources :likes, only: [:index, :create, :destroy]
    resources :comments, only: [:create, :destroy]
  end

  # ヘルスチェック
  get "up" => "rails/health#show", as: :rails_health_check
end