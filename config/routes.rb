Rails.application.routes.draw do
  # ホームページ
  root "posts#index"

  resources :articles do
    collection do
      get :by_category
      get :by_tag
    end
  end

  resources :categories, only: [:index, :show]
  resources :tags, only: [:index, :show]

  # ユーザー関連
  resources :users, only: [:new, :create, :show]

  # セッション（ログイン/ログアウト）
  get    '/login',  to: 'sessions#new'
  post   '/login',  to: 'sessions#create'
  delete '/logout', to: 'sessions#destroy'

  get '/logout', to: 'sessions#destroy'
  delete '/logout', to: 'sessions#destroy'


  # 投稿関連
  resources :posts do
    resources :likes, only: [:create, :destroy]
    resources :comments, only: [:create, :destroy]
  end

  # ヘルスチェック
  get "up" => "rails/health#show", as: :rails_health_check

  #root 'articles#index'

end