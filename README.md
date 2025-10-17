# 📝 BrightTalk — README（改訂版）

BrightTalk は、Ruby on Rails 8 と Vite をベースにした  
モダンな Web コンテンツプラットフォームです。  
Markdown エディタ、動画プレイヤー、Passkeyログインなどを統合し、  
開発者・クリエイターが快適に投稿・共有できる環境を提供します。

---

## 🚀 主な特徴

### 📝 投稿・編集機能
- Markdown対応エディタ（CodeMirror 6、目的/対象読者などの構造化フィールドと同期）
- 投稿タイプ・カテゴリー・タグの複合管理
- 画像・動画の複数添付（ActiveStorage + S3、signed_id対応）
- 自動保存ドラフト／公開ステータスの切り替え
- 投稿者別の前後記事・関連記事抽出

### 🎥 メディア & ファイル
- Video.js による動画再生（Stimulusコントローラ制御、Playwrightテストで検証）
- ActiveStorage Direct Upload のチューニング（大容量対応・日本語ファイル名サポート）
- ruby-vips による EXIF 削除と画像検証
- Markdown `attachment:` スキームでの埋め込み整形

### 🔐 認証・ユーザー管理
- Devise + WebAuthn（Passkey対応、Passkey登録・認証のRESTエンドポイントあり）
- FriendlyId スラッグ生成、プロフィール編集、SNSリンク検証
- アバター／ヘッダー画像の添付とバリデーション

### 💬 コメント機能
- BrightTalk iOS アプリからの投稿専用（`X-Client-Platform: BrightTalk-iOS` ヘッダーを要求）
- 有料フラグ（`paid`）・ポイント付与・位置情報（緯度経度）を記録
- いいね（Turbo対応）とコメント表示順位制御

### 💻 フロントエンド
- **Vite + Stimulus + Turbo**
- CodeMirror 6 ベースの Markdown エディタ
- Flatpickr による日付選択
- Bootstrap 5 + Font Awesome + Bootstrap Icons

### 📡 配信・連携
- RSS / Atom フィード（`/feeds/rss`, `/feeds/atom`）
- サイトマップ生成とキャッシュ配信（`/sitemap.xml` + `SitemapGenerator`）
- JSON レスポンスを提供する投稿一覧 API（`/posts.json`）
- AWS SES 経由のお問い合わせメール送信

### ☁️ インフラ・デプロイ
- Kamal による AWS EC2 / Lightsail デプロイ
- S3 + CloudFront 連携
- SQLite3（アプリ・Solid Queue・Solid Cache を共通で使用）
- CI/CD: GitHub Actions
- Solid Queue / Solid Cache の組み込み

---

## 🛠 技術スタック

| 分類 | 使用技術 |
|------|------------|
| **言語** | Ruby 3.4.4 / JavaScript (ES2023) |
| **フレームワーク** | Ruby on Rails 8.0.2 |
| **フロントエンド** | Vite + Stimulus + Turbo |
| **エディタ** | CodeMirror 6 |
| **動画プレイヤー** | Video.js |
| **CSS Framework** | Bootstrap 5 |
| **アイコン** | Font Awesome 6 / Bootstrap Icons |
| **認証** | Devise + WebAuthn (Passkey) |
| **画像処理** | ruby-vips + image_processing |
| **ストレージ** | AWS S3 |
| **デプロイ** | Kamal |
| **CI/CD** | GitHub Actions |

---

## 📋 動作環境

- macOS または Linux 環境
- Ruby 3.4.4+
- Node.js LTS（18 以上）
- Yarn or npm
- libvips（画像処理用）
- Foreman または Overmind などの Procfile ランナー
- Playwright が利用するブラウザバイナリ（`npx playwright install` で導入）

---

## ⚙️ セットアップ手順

### 1️⃣ リポジトリをクローン
```bash
git clone https://github.com/mitani-darwin/BrightTalk.git
cd BrightTalk
```

### 2️⃣ 依存パッケージのインストール
```bash
bundle install
npm install
npx playwright install --with-deps    # JavaScriptテストで Playwright を利用する場合
```

### 3️⃣ システム依存関係のインストール
```bash
# macOS
brew install vips
# Ubuntu/Debian
sudo apt install libvips
# foreman CLI（ターミナルマルチプロセス管理）
gem install foreman # 既に入っていれば不要 / または bundle exec foreman で利用
```

### 4️⃣ データベース初期化
```bash
bin/rails db:prepare   # create + migrate を実行
bin/rails db:seed      # 投稿タイプなどのマスターデータ投入
```

---

## 🔐 環境変数・認証情報

- `.env.development` / `.env.production` はサンプルとして置いてあります。実際の運用では `.env.local` などを作成し、**自身の値で上書きしてください（既存の秘密情報は使用しない）**。
- 必須項目（環境変数または Rails Credentials いずれか）  
  - `AWS_ACCESS_KEY_ID`, `AWS_SECRET_ACCESS_KEY`, `AWS_REGION`, `S3_BUCKET_NAME`（ActiveStorage / SES 用）  
  - `RAILS_MASTER_KEY`（`config/credentials.yml.enc` の復号に使用）  
  - `WEBAUTHN_RP_ID`, `WEBAUTHN_RP_NAME`, `WEBAUTHN_ALLOWED_ORIGINS`（WebAuthn設定）  
  - `MAIL_FROM`, `MAIL_DELIVERY_METHOD` 等のメール設定、`GOOGLE_ANALYTICS_ID`（任意）
- 開発環境の ActiveStorage は `config/environments/development.rb` で `:amazon` を使用しています。S3 を用意できない場合は `:local` に変更し、`storage/` ディレクトリを利用してください。
- `config/sitemap.rb` の `SitemapGenerator::Sitemap.default_host` も自身のドメインに置き換えてください。
- 秘密情報は Git へコミットせず、`.env*` や CI のシークレットストアで安全に管理します。

---

## 🧩 開発サーバー起動

`Procfile.dev` を利用して Rails と Vite を同時起動します。
```bash
bundle exec foreman start -f Procfile.dev
```

またはターミナルを2つ開き、下記を個別に実行してください：
```bash
# Terminal 1
bin/rails server
# Terminal 2
bin/vite dev --port 3036 --strictPort
```

アクセス： 👉 http://localhost:3000

※ Vite クライアントは開発環境のみで自動インジェクトされます。

---

## 🧪 テスト

### Rails側
```bash
bin/rails test
```

### JavaScript（Vite + Node）
```bash
npm run test:all
```
※ 初回は `npx playwright install --with-deps` を実行してブラウザを導入してください。  

個別に実行したい場合は `npm run test:passkey` などのサブコマンド、または `./run_js_tests.sh [option]` を利用できます。

Rails 側は `RAILS_ENV=test` で ActiveStorage の Disk サービスを使用します（S3 接続は不要）。

---

## 🔍 フィード / API / サイトマップ

- RSS: `GET /feeds/rss`  
  Atom: `GET /feeds/atom`
- 投稿一覧 API: `GET /posts.json`  
  - クエリ: `category_id`, `post_type_id`, `date_range (例: 2025-01-01 から 2025-01-31)`
- コメント投稿 / 削除 API は iOS アプリ専用です。リクエストヘッダー `X-Client-Platform: BrightTalk-iOS` を付与し、認証済みユーザーのみが利用できます。
- サイトマップ: `GET /sitemap.xml`  
  - 24時間以内のキャッシュが存在しない場合 `SitemapGenerator` で再生成します。  
  - 手動で更新する場合: `bundle exec rake sitemap:refresh`

---

## 📦 デプロイ

Kamal を使用してAWSへデプロイ。

```bash
kamal setup   # 初回セットアップ
kamal deploy  # 更新デプロイ
```

設定は `config/deploy.yml` で管理。イメージ名・ボリューム・Kamal エイリアス・必要な環境変数（`RAILS_MASTER_KEY`, `AWS_*`, `GITHUB_*`, `SSH_KEY_PATH` など）を適宜更新してください。

---

## 📄 ドキュメント & ツール

- `docs/` … Passkey 実装メモ、Direct Upload の調査レポートなど補足資料
- `.kamal/` … Kamal で利用する設定・テンプレート群
- `terraform/` … AWS リソースを構成する Terraform モジュールと環境別設定
- `run_js_tests.sh` … JavaScript テストをプリセット付きで実行するヘルパースクリプト
- `Procfile.dev` … 開発時に Rails / Vite を同時起動するための定義

---

## 🎨 デザイン・UIメモ

- 背景色例：`#caf5f7`  
- 有料コメントは淡いゴールド背景（`#fff6d5`）  
- CodeMirrorテーマ：ライト（customized）  
- Video.js：デフォルトスキン使用（Stimulus連携済）

---

## 🧱 ディレクトリ構成（主要）

```
app/
 ├─ controllers/
 │   ├─ posts_controller.rb
 │   ├─ comments_controller.rb
 │   ├─ passkey_authentications_controller.rb
 │   └─ devise/passkeys_controller.rb
 ├─ views/
 │   ├─ layouts/application.html.erb
 │   ├─ posts/
 │   └─ feeds/
 ├─ javascript/
 │   ├─ controllers/（CodeMirror / Video.js / Flatpickr）
 │   ├─ entrypoints/
 │   ├─ application.js
 │   └─ passkey.js
 ├─ frontend/
 │   └─ entrypoints/（Vite エントリ & CSS）
 ├─ models/
 │   ├─ post.rb
 │   ├─ user.rb
 │   └─ webauthn_credential.rb
config/
 ├─ application.rb
 ├─ environments/
 ├─ deploy.yml
 ├─ sitemap.rb
 └─ vite.json
.kamal/
docs/
terraform/
Procfile.dev
run_js_tests.sh
package.json
Gemfile
```

---

## 🤝 コントリビューション

1. ブランチを切る：  
   ```bash
   git checkout -b feature/awesome
   ```
2. コーディング規約：Rubocop / ESLint 準拠  
3. PRを送る前にテストを実行

---

## 📄 ライセンス

MIT License.  
詳細は [LICENSE](LICENSE) を参照。

---

## 🌟 開発メモ

- `app/frontend/entrypoints/application.js` → Vite から Rails アセットを読み込み
- Stimulus コントローラ（`code_editor` / `video_player` / `flatpickr`）は Playwright で CI テスト済
- ActiveStorage は Direct Upload + S3 前提で、EXIF 除去などを after_commit で処理
- `app/javascript/passkey.js` が WebAuthn (Passkey) 登録・認証を一括で担当
- コメントの表示順は `Comment.ordered_for_display` で制御（有料・ポイント・作成日時）
- iOS アプリ（Swift）からの投稿を想定し、`X-Client-Platform` ヘッダーでアクセス制御

---

## 💬 Contact

- Author: **darwin2008**
- Repository: [BrightTalk GitHub](https://github.com/mitani-darwin/BrightTalk)
- Issues: GitHub Issues にて受付中

---

✨ **BrightTalk – 明るい対話で、知識と創造をつなぐプラットフォーム。**
