# 投稿関連のルーティング
Rails.application.routes.draw do
  # 投稿関連のルート
  resources :posts do
    # 下書き機能を追加
    collection do
      get :drafts
      post :auto_save
    end

    # 画像削除機能を追加
    member do
      delete :delete_image
    end

    # いいね機能を追加
    resources :likes, only: [ :create, :destroy ]
    resources :comments, only: [ :create, :destroy ]
  end
end
