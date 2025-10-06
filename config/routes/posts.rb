# 投稿関連のルーティング
Rails.application.routes.draw do
  # 投稿関連のルート
  resources :posts do
    # 下書き機能を追加
    collection do
      get :drafts
      post :auto_save
      delete :bulk_destroy
    end

    # 画像・動画削除機能を追加
    member do
      delete :delete_image
      delete :delete_video
    end

    # いいね機能を追加
    resources :likes, only: [ :create, :destroy ]
    resources :comments, only: [ :create, :destroy ]
  end

  # Handle POST requests to /posts/:id (which should be PATCH/PUT for updates)
  # This fixes forms that incorrectly use POST method for updating existing posts
  #  post '/posts/:id', to: 'posts#update', constraints: { id: /(?!auto_save)[^\/]+/ }
end
