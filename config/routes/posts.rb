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
    resources :bookmarks, only: [ :create, :destroy ]
    resources :comments, only: [ :create, :destroy ]
  end

  # ユーザーごとの投稿一覧
  get 'users/:user_id/posts', to: 'posts#user_posts', as: :user_posts

  # DELETE /posts（ID無し）のフォールバック（外部からの誤ったDELETEリクエスト対策）
  delete '/posts', to: 'posts#bulk_destroy'

  # Handle POST requests to /posts/:id (which should be PATCH/PUT for updates)
  # This fixes forms that incorrectly use POST method for updating existing posts
  #  post '/posts/:id', to: 'posts#update', constraints: { id: /(?!auto_save)[^\/]+/ }
end
