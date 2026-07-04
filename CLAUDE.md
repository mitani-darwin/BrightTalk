# CLAUDE.md

このファイルは、このリポジトリで作業する Claude Code (claude.ai/code) に向けたガイダンスを提供します。

## コマンド

### セットアップ
```bash
bundle install
npm install
bin/rails db:prepare   # create + migrate
bin/rails db:seed      # 投稿タイプなどのマスターデータを投入
```

### 開発サーバーの起動
```bash
bundle exec foreman start -f Procfile.dev   # web(Rails)・vite・tailwindcss:watch をまとめて起動
```
個別に起動する場合: `bin/rails server`、`bin/vite dev --port 3036 --strictPort`、`bin/rails tailwindcss:watch`。

### Rails テスト
```bash
bin/rails test                      # フルスイート（test/models, controllers, integration）
bin/rails test test/models/post_test.rb
bin/rails test test/models/post_test.rb:23   # 行番号指定で単一テストを実行
bin/rails test:system               # Capybara/Selenium によるシステムテスト
```
`RAILS_ENV=test` では ActiveStorage の Disk サービスを使用します（S3接続は不要）。CI では `PARALLEL_WORKERS=1` で実行されます。

`bin/rails test` が拾うのは `*_test.rb` に一致するファイルのみです。リポジトリには他に、特定の不具合調査のために残された大量の一時的な `test/test_*.rb`、`test/models/test_*.rb`、`test/*.html` ファイル（auto-save、CodeMirror、モーダルなど）があります。これらは実行対象のスイートには**含まれておらず**、必要であれば `ruby` で直接実行してください。

### JavaScript テスト
```bash
npx playwright install --with-deps   # 初回のみ
npm run test:all                     # または `npm test`
npm run test:passkey                 # 個別スイート。他は package.json を参照
./run_js_tests.sh [option]           # 薄いラッパー。`./run_js_tests.sh help` でオプション一覧
```
これらはテストフレームワークを使わないプレーンな Node スクリプトで、`node test/test_*.js` として直接実行されます。

### Lint / 静的解析
```bash
bundle exec rubocop        # Omakase Rails スタイル（.rubocop.yml は rubocop-rails-omakase を継承）
bundle exec brakeman
scripts/check_no_bootstrap_in_tw.sh   # app/views 全体に Bootstrap クラスが混入していると失敗する
```

### デプロイ
```bash
kamal setup    # 初回のみ
kamal deploy   # 以降の更新デプロイ
```
設定は `config/deploy.yml`。シークレットは `RAILS_MASTER_KEY`、`AWS_*` など。

## アーキテクチャ

### ルーティング
`config/routes.rb` にはトップレベルのルート（root、feeds、sitemap）のみが定義されており、それ以外は `draw(:posts)`、`draw(:auth)`、`draw(:users)` などを通じて `config/routes/*.rb` に委譲されています。ルートを追加する際は、メインファイルではなく `config/routes/` 配下の該当ファイルを探してください。

### フロントエンドは Tailwind CSS に統一済み（Bootstrap は撤去済み）
かつて `app/views/tw/**` に新規 Tailwind ビュー、`app/views/**` に旧 Bootstrap ビューが混在する移行期があったが（背景は `docs/Tailwindへ移行.md` 等の `docs/*Tailwind*`/`docs/*Bootstrap*` 系メモを参照）、全ページの Tailwind 化が完了し `app/views/tw/**` は廃止・`app/views/**` に統合された。レイアウトも `layouts/application.html.erb` 1本（`<body class="tw ...">`）に統一されており、`layouts/tailwind.html.erb` や `Tailwind::BaseController`、`PostsController` の `prepend_view_path` は存在しない。
- `app/views/shared/_tailwind_styles.html.erb` は `.tw` スコープの `@layer components` で `.btn`/`.card`/`.badge`/`.form-control`/`.form-select`/`.nav-link`/`.pill`/`.text-muted`/`.bg-primary|secondary|info|warning|danger` などを Tailwind の `@apply` で実装している。これは Bootstrap ではなく、この項目のクラス名は意図的に踏襲された社内コンポーネント層なので、削除したり素の Tailwind ユーティリティに書き換えたりしないこと。
- `bin/rails tailwindcss:build`（または `Procfile.dev` 経由）で生成される `app/assets/builds/tailwind.css` が本番相当のスタイル。開発中に見つからない場合は CDN 版 Tailwind にフォールバックする（`shared/_tailwind_styles.html.erb` 参照）。
- CI が回帰を防いでいます: `scripts/check_no_bootstrap_in_tw.sh` が `app/views` 全体を対象に、`.tw` シムに存在しない Bootstrap 専用トークン（`container`/`row`/`col-*`/`d-flex`/`navbar`/`dropdown-menu`/`modal`/`data-bs-*` など）を `class="..."`/`class: "..."` 属性内でのみ検出します（`.btn`/`.card`/`.badge`/`.form-control` 等のシムクラスは意図的に除外）。新しいビューを追加する際もこのチェックを通してください。

### 認証
Devise が通常のセッション・登録処理を担当し、Passkey/WebAuthn は並行する認証経路です（`webauthn` gem、`WebauthnCredential` モデル、ブラウザ側の儀式を担う `app/javascript/passkey.js`、`Devise::PasskeysController` + `PasskeyAuthenticationsController` + `PasskeyRegistrationsController`）。`ApplicationController#public_access_allowed?` が、どのコントローラー／アクションの組み合わせが `authenticate_user!` をスキップするかを決める唯一のゲートです。あるアクションがログイン必須かどうかを決めつける前に、まずここを確認してください（例: `posts#index`/`#show` や passkey/session 系のコントローラーは意図的に公開されています）。

`ApplicationController` にはさらに、Rails 8 + Devise 4.9 の CSRF 互換性のためのワークアラウンド（`handle_csrf_verification`、`set_csrf_cookie`）がいくつかあり、リクエストパラメータに CSRF トークンが欠けている場合にセッション側のトークンを手動で params に注入しています。これは意図的な互換性対応であり、削除して良いデバッグコードではないので、理由を理解せずに取り除かないでください。

### 投稿・メディアパイプライン
`Post`（`app/models/post.rb`）がドメインの複雑さの大部分を担っています。
- FriendlyId によるスラッグ生成、`draft`/`published` の enum ステータス。バリデーションは `auto_saved_draft?` によって緩和されており、未完成な下書きの自動保存がバリデーションで失敗しないようになっています。
- ActiveStorage/S3 経由の `has_many_attached :images` と `:videos`。
- `after_commit` フック（テスト環境ではスキップ）は2つの異なる処理を行います。画像は **同期的に** リクエスト内で `ruby-vips` によって EXIF を削除し、削除済みファイルを S3 に再アップロードします（`process_images_for_exif_removal`）。動画は `VideoUploadJob`（Solid Queue）に渡され、非同期で S3 にアップロードされます（`process_videos_for_async_upload`）。どちらも blob のメタデータフラグ（`exif_removed`、`async_upload_completed`）を使って、以降の保存時に再処理されないようにしています。
- `related_posts` / `previous_post_by_author` / `next_post_by_author` は、タグ → カテゴリー → 投稿タイプ → 新着順にフォールバックしながら「前後・関連記事」ナビゲーションを実装しています。

### コメントは iOS アプリ専用
コメントの作成・削除は、`X-Client-Platform: BrightTalk-iOS` リクエストヘッダーを持つ BrightTalk iOS アプリからのみ許可されており、`ApplicationController#ios_app_request?` / `#ios_app_only_access!` でチェックされています。コメントは `paid` フラグと `points` を持ち、表示順は単純な `created_at` ではなく `Comment.ordered_for_display`（有料・ポイント降順、その後に新着順）で制御されます。

### バックグラウンドジョブ・インフラ
Solid Queue、Solid Cache、Solid Cable はいずれもアプリの SQLite データベースを共有しています（Redis は不要）。現時点でのカスタムジョブは `VideoUploadJob` のみです。

### フィード / API / サイトマップ
- `GET /feeds/rss`、`/feeds/atom`（`/rss.xml`、`/atom.xml` としてもエイリアスされる）
- `GET /posts.json` は `category_id`、`post_type_id`、`date_range` のクエリパラメータに対応
- `GET /sitemap.xml` はキャッシュ済みサイトマップが24時間より古い場合に `SitemapGenerator` で再生成します。強制的に更新する場合は `bundle exec rake sitemap:refresh`
