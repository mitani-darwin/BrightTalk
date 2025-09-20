Rails.application.routes.draw do
  # ==========================================
  # メインルート
  # ==========================================
  root "posts#index"

  # ==========================================
  # 機能別ルーティング読み込み
  # ==========================================

  # 認証機能（Devise）
  draw(:auth)

  # 投稿機能（投稿、いいね、コメント）
  draw(:posts)

  # ユーザー機能（プロフィール、アカウント設定）
  draw(:users)

  # カテゴリー機能
  draw(:categories)

  # 投稿タイプ機能
  draw(:post_types)

  # システム機能（ヘルスチェック、PWA）
  draw(:system)

  # 静的ページ機能（プライバシーポリシーなど）
  draw(:pages)

  # お問い合わせ機能
  draw(:contacts)

  # Sitemap
  get '/sitemap.xml', to: 'sitemaps#index', defaults: { format: 'xml' }

  # RSS/Atom feeds
  get '/feeds/rss', to: 'feeds#rss', defaults: { format: 'rss' }
  get '/feeds/atom', to: 'feeds#atom', defaults: { format: 'atom' }
  get '/rss.xml', to: 'feeds#rss', defaults: { format: 'rss' }
  get '/atom.xml', to: 'feeds#atom', defaults: { format: 'atom' }
end
