# カテゴリー関連のルーティング
Rails.application.routes.draw do
  # カテゴリー関連のルート
  resources :categories, only: [:create, :index]
end