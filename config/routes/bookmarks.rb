# ブックマーク関連のルーティング
Rails.application.routes.draw do
  resources :bookmarks, only: [:index]
end
