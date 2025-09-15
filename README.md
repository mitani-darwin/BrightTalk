# BrightTalk

コンテンツ共有とコミュニティ交流のためのモダンなRuby on Railsアプリケーション。高度な認証機能、マルチメディアサポート、包括的なコンテンツ管理機能を備えています。

## 🌟 機能

### 基本機能
- **コンテンツ作成・管理**: Markdownサポート付きリッチテキスト投稿
- **マルチメディアサポート**: 画像・動画のアップロードと自動処理
- **ユーザー認証**: 従来のメール/パスワード認証とモダンなPasskey認証
- **コミュニティ機能**: コメント、いいね、ユーザープロフィール
- **コンテンツ整理**: カテゴリ、タグ、検索機能

### 高度な機能
- **Passkey認証**: 生体認証/ハードウェアキーを使用したWebAuthnベースのパスワードレスログイン
- **動画処理**: CloudFront CDNサポート付きVideo.jsプレーヤー統合
- **画像処理**: ruby-vipsを使用した自動EXIF削除と最適化
- **PDF出力**: ユーザー投稿のPDF版生成
- **レスポンシブデザイン**: モバイルファーストのBootstrapベースUI
- **リアルタイム機能**: Turboによる高速インタラクション

### セキュリティとパフォーマンス
- **コンテンツセキュリティポリシー**: XSS攻撃からの保護
- **CORS設定**: 安全なクロスオリジンリソース共有
- **SSL/TLS**: 本番環境でのHTTPS強制
- **キャッシング**: パフォーマンス向上のためのSolid Cache
- **バックグラウンドジョブ**: 非同期処理のためのSolid Queue

## 🛠 技術スタック

### バックエンド
- **Ruby on Rails 8.0+**: モダンアーキテクチャを持つ最新Rails機能
- **SQLite**: 開発・本番用データベース
- **Puma**: 高性能Webサーバー
- **Solid Cache/Queue/Cable**: キャッシング、ジョブ、WebSocket用のRails 8 solidスタック

### フロントエンド
- **Hotwire**: リアクティブWebアプリのためのTurbo + Stimulus
- **Bootstrap 5**: レスポンシブCSSフレームワーク
- **Video.js**: 高機能HTML5動画プレーヤー
- **Sass**: dart-sassによるCSS前処理

### 認証とセキュリティ
- **Devise**: ユーザー認証と管理
- **WebAuthn**: パスキーによるパスワードレス認証
- **bcrypt**: 安全なパスワードハッシュ化

### ファイル処理とストレージ
- **Active Storage**: Railsファイルアップロードシステム
- **AWS S3**: IAM認証付きクラウドストレージ
- **ruby-vips**: 高性能画像処理
- **CloudFront**: 動画配信用CDN

### コンテンツ処理
- **Redcarpet**: MarkdownからHTMLへの変換
- **Grover**: ChromeベースのPDF生成
- **FriendlyId**: SEOフレンドリーなURL

### 開発とデプロイ
- **Kamal**: モダンデプロイツール
- **Importmap**: バンドルなしのJavaScript
- **Brakeman**: セキュリティ脆弱性スキャナー
- **RuboCop**: コードスタイルと品質

## 📋 必要要件

- Ruby 3.1以上
- Node.js 18+（JavaScript依存関係のため）
- SQLite 3
- Chrome/Chromium（PDF生成のため）

### オプション
- AWSアカウント（S3ストレージとCloudFront CDNのため）
- SMTPサーバー（メール通知のため）

## 🚀 インストール

### 1. リポジトリのクローン
```bash
git clone https://github.com/yourusername/brighttalk.git
cd brighttalk
```

### 2. 依存関係のインストール
```bash
# Ruby gemのインストール
bundle install

# JavaScript依存関係のインストール
bin/importmap pin --all
```

### 3. データベースセットアップ
```bash
# データベースの作成とマイグレーション
rails db:create
rails db:migrate

# 初期データの投入（オプション）
rails db:seed
```

### 4. 環境設定
```bash
# 環境設定ファイルのコピー
cp .env.example .env

# 設定の編集
nano .env
```

### 5. アプリケーションの起動
```bash
# 開発サーバー
rails server

# または複数プロセス用のForeman使用
./bin/dev
```

`http://localhost:3000` にアクセスしてアプリケーションを利用できます。

## ⚙️ 設定

### 環境変数
ルートディレクトリに `.env` ファイルを作成：

```env
# データベース
DATABASE_URL=sqlite3:storage/production.sqlite3

# AWS設定（オプション）
AWS_ACCESS_KEY_ID=your_access_key
AWS_SECRET_ACCESS_KEY=your_secret_key
AWS_REGION=us-east-1
AWS_S3_BUCKET=your-bucket-name
CLOUDFRONT_DISTRIBUTION_URL=https://your-cloudfront-url

# メール設定
SMTP_SERVER=smtp.example.com
SMTP_PORT=587
SMTP_USERNAME=your_username
SMTP_PASSWORD=your_password

# アプリケーション設定
RAILS_ENV=production
SECRET_KEY_BASE=your_secret_key_base
```

### WebAuthn設定
アプリケーションはパスキー認証をサポートしています。`config/initializers/webauthn.rb`で許可するオリジンを設定：

```ruby
# 開発環境
config.allowed_origins = [
  "http://localhost:3000",
  "http://127.0.0.1:3000"
]

# 本番環境
config.allowed_origins = ["https://yourdomain.com"]
```

### AWS S3セットアップ（オプション）
ファイルアップロードとストレージのため：

1. S3バケットを作成
2. S3権限を持つIAMユーザーを設定
3. 動画配信用のCloudFrontディストリビューションを設定
4. `config/storage.yml`で認証情報を更新

## 🎯 使用方法

### ユーザー登録
- 従来のメール/パスワード登録
- パスワードレス認証のためのパスキー登録
- メール確認が必要

### コンテンツ作成
1. リッチMarkdownコンテンツで投稿を作成
2. 画像と動画をアップロード
3. カテゴリとタグで整理
4. 公開前にプレビュー

### Markdownサポート
アプリケーションは包括的なMarkdown記法をサポート：

```markdown
# 見出し
**太字テキスト**
*斜体テキスト*
- リスト
[リンク](https://example.com)
![画像](image-url)
```

### 動画統合
動画をアップロードし、投稿で参照：
```markdown
[動画 filename.mp4](attachment:filename.mp4)
```

### PDF出力
オフライン閲覧や共有のための投稿のPDF版を生成。

## 🏗️ 開発

### テストの実行
```bash
# すべてのテストを実行
rails test

# 特定のテストファイルを実行
rails test test/models/user_test.rb
```

### コード品質
```bash
# セキュリティスキャン
bundle exec brakeman

# コードスタイルチェック
bundle exec rubocop

# スタイル問題の自動修正
bundle exec rubocop -a
```

### データベース操作
```bash
# マイグレーション生成
rails generate migration AddColumnToTable column:type

# マイグレーション実行
rails db:migrate

# マイグレーションのロールバック
rails db:rollback

# データベースリセット（開発環境）
rails db:drop db:create db:migrate db:seed
```

## 🚀 デプロイ

### Kamal使用（推奨）
```bash
# デプロイセットアップ
kamal setup

# アプリケーションデプロイ
kamal deploy

# ステータス確認
kamal app details
```

### 手動デプロイ
1. Ruby と依存関係を持つ本番サーバーをセットアップ
2. リポジトリをクローンしgemをインストール
3. 環境変数を設定
4. データベースマイグレーションを実行
5. アセットをプリコンパイル
6. アプリケーションサーバーを起動

### 本番環境チェックリスト
- [ ] 環境変数が設定済み
- [ ] データベースがマイグレート済み
- [ ] SSL証明書がインストール済み
- [ ] AWS S3バケットが設定済み
- [ ] メールサービスが設定済み
- [ ] バックグラウンドジョブプロセッサが実行中
- [ ] 監視とログが設定済み

## 📖 API ドキュメント

### 認証エンドポイント
- `POST /users/sign_in` - ユーザーログイン
- `POST /users/sign_up` - ユーザー登録
- `DELETE /users/sign_out` - ユーザーログアウト
- `POST /passkey_registrations` - パスキー登録
- `POST /passkey_authentications` - パスキー認証

### コンテンツエンドポイント
- `GET /posts` - 投稿一覧
- `POST /posts` - 投稿作成
- `GET /posts/:id` - 投稿表示
- `PUT /posts/:id` - 投稿更新
- `DELETE /posts/:id` - 投稿削除

### ユーザーエンドポイント
- `GET /users/:id` - ユーザープロフィール
- `PUT /users/:id` - プロフィール更新
- `GET /users/:id/posts` - ユーザー投稿

## 🤝 コントリビューション

1. リポジトリをフォーク
2. 機能ブランチを作成（`git checkout -b feature/amazing-feature`）
3. 変更をコミット（`git commit -m 'Add amazing feature'`）
4. ブランチにプッシュ（`git push origin feature/amazing-feature`）
5. プルリクエストを開く

### 開発ガイドライン
- RubyとRailsのベストプラクティスに従う
- 新機能のテストを記述
- 必要に応じてドキュメントを更新
- 提出前にコード品質チェックを実行
- 意味のあるコミットメッセージを使用

### コードスタイル
- RuboCopガイドラインに従う
- 説明的な変数名とメソッド名を使用
- 複雑なロジックにコメントを追加
- メソッドを小さく集中的に保つ

## 🐛 トラブルシューティング

### よくある問題

#### パスキー認証の失敗
- `config/initializers/webauthn.rb`のWebAuthn設定を確認
- 本番環境でHTTPSが有効になっていることを確認
- 許可オリジンがドメインと一致することを確認

#### 動画アップロードの問題
- AWS S3の認証情報と権限を確認
- CloudFrontディストリビューション設定を確認
- 十分なストレージ容量を確保

#### 画像処理エラー
- ruby-vipsのシステム依存関係をインストール
- 画像処理に十分なメモリがあることを確認
- サポートされている画像フォーマットを確認

#### データベース接続エラー
- データベースファイルの権限を確認
- SQLiteが正しくインストールされていることを確認
- 設定のデータベースパスを確認

### ヘルプの取得
- [Issues](https://github.com/yourusername/brighttalk/issues)ページを確認
- `log/`ディレクトリのアプリケーションログを確認
- 詳細なエラー情報のためにデバッグモードを有効化

## 📄 ライセンス

このプロジェクトはMITライセンスの下でライセンスされています。詳細は[LICENSE](LICENSE)ファイルをご覧ください。

## 🙏 謝辞

- 優れたフレームワークを提供するRailsコミュニティ
- パスワードレス認証標準を提供するWebAuthnワーキンググループ
- 堅牢な動画プレーヤーを提供するVideo.jsチーム
- レスポンシブCSSフレームワークを提供するBootstrapチーム
- このプロジェクトの改善に協力するすべてのコントリビューター

---

**BrightTalk** - モダンなWeb技術でコミュニティを活性化