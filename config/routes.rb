Rails.application.routes.draw do
  # ホームページ
  root "posts#index"

  # ユーザー関連
  resources :users, only: [:new, :create, :show]

  # セッション（ログイン/ログアウト）
  get    '/login',  to: 'sessions#new'
  post   '/login',  to: 'sessions#create'
  delete '/logout', to: 'sessions#destroy'

  # 投稿関連
  resources :posts do
    resources :comments, only: [:create, :destroy]
  end

  # ヘルスチェック
  get "up" => "rails/health#show", as: :rails_health_check
end