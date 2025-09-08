# カテゴリー関連のルーティング
Rails.application.routes.draw do
  # カテゴリー関連のルート（階層構造対応）
  resources :categories do
    member do
      get :children # 指定カテゴリーの子カテゴリー一覧
    end

    collection do
      get :hierarchical # 階層構造の全カテゴリー取得
    end
  end
end
