
Rails.application.routes.draw do
  # Deviseルーティング
  devise_for :users, controllers: {
    registrations: 'users/registrations',
    confirmations: 'users/confirmations'
  }

  root 'posts#index'

  # 投稿関連のルート
  resources :posts do
    # 下書き機能を追加
    collection do
      get :drafts
    end

    # いいね機能を追加
    resources :likes, only: [:create, :destroy]
    resources :comments, only: [:create, :destroy]
  end

  # カテゴリー関連のルート
  resources :categories, only: [:create, :index]

  # ユーザー関連のルート
  resources :users, only: [:show] do
    collection do
      get :registration_pending
    end
    member do
      get :account
      get :edit_account
      patch :update_account
      get :edit_password
      patch :update_password
    end
  end

  get "up" => "rails/health#show", as: :rails_health_check
  get "service-worker" => "rails/pwa#service_worker", as: :pwa_service_worker
  get "manifest" => "rails/pwa#manifest", as: :pwa_manifest
end