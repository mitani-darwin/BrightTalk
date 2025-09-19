# config/routes/contacts.rb
Rails.application.routes.draw do
  # お問い合わせ機能のルーティング
  # Contact form routing

  resources :contacts, only: [ :new, :create ] do
    collection do
      get :success, path: "success", as: :success
    end
  end

  # 別名でのアクセスも可能にする
  get "contact", to: "contacts#new"
  get "contact/success", to: "contacts#success"
end
