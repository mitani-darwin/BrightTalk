# ユーザー関連のルーティング
Rails.application.routes.draw do
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
end