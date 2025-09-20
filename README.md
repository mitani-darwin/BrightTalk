# BrightTalk

BrightTalkは、現代的なWebテクノロジーを活用したソーシャルメディア・コンテンツ管理プラットフォームです。ユーザーが投稿の作成、編集、共有を行い、マルチメディアコンテンツ（画像・動画）を扱うことができます。

## 🚀 主な機能

### 📝 投稿機能
- **投稿管理**: 作成、編集、削除、公開/非公開の設定
- **下書き機能**: 自動保存による下書き管理
- **マルチメディア対応**: 画像・動画のアップロード・管理
- **Markdown対応**: Markdownによる豊富なテキスト表現

### 👥 ユーザー管理
- **認証機能**: Deviseによる安全なユーザー認証
- **WebAuthn/Passkey**: 最新の認証技術サポート
- **プロフィール管理**: ユーザー情報とアカウント設定
- **多言語対応**: 日本語ローカライゼーション

### 🎯 その他の機能
- **カテゴリー機能**: 投稿の分類・整理
- **コメント・いいね機能**: ユーザー間のインタラクション
- **ページネーション**: 効率的なコンテンツ表示
- **お問い合わせ機能**: ユーザーサポート
- **PDF生成**: コンテンツのPDF出力
- **AWS S3連携**: クラウドストレージとの統合

## 🛠️ 技術スタック

### バックエンド
- **Ruby on Rails**: 8.0.2
- **Ruby**: 3.4.4
- **データベース**: SQLite3 (本番環境)
- **認証**: Devise + WebAuthn
- **画像処理**: ruby-vips + image_processing

### フロントエンド
- **CSS Framework**: Bootstrap 5
- **JavaScript**: Stimulus + Turbo
- **Icons**: Bootstrap Icons + Font Awesome 6
- **Code Editor**: CodeMirror
- **Video Player**: Video.js

### インフラ・デプロイ
- **デプロイツール**: Kamal
- **Webサーバー**: Puma + Thruster
- **クラウド**: AWS S3
- **CI/CD**: GitHub Actions

## 📋 必要環境

- Ruby 3.4.4 以上
- Node.js (最新のLTS版推奨)
- SQLite3
- libvips (画像処理用)

## 🔧 セットアップ

### 1. リポジトリのクローン
```bash
git clone https://github.com/your-username/BrightTalk.git
cd BrightTalk
```

### 2. 依存関係のインストール
```bash
# Ruby gems のインストール
bundle install

# JavaScript パッケージのインストール (必要に応じて)
yarn install
```

### 3. システム依存関係の設定
```bash
# Ubuntu/Debian の場合
sudo apt-get update
sudo apt-get install -y libvips

# macOS の場合
brew install vips
```

### 4. データベースのセットアップ
```bash
# データベースの作成
bin/rails db:create

# マイグレーションの実行
bin/rails db:migrate

# テストデータの投入（オプション）
bin/rails db:seed
```

### 5. 環境変数の設定
`.env` ファイルを作成し、必要な環境変数を設定してください：

```bash
# AWS S3 設定（オプション）
AWS_ACCESS_KEY_ID=your_access_key
AWS_SECRET_ACCESS_KEY=your_secret_key
AWS_REGION=ap-northeast-1
AWS_S3_BUCKET=your-bucket-name

# Google Analytics（本番環境のみ）
GOOGLE_ANALYTICS_ID=GA_MEASUREMENT_ID

# メール設定（SES使用時）
AWS_SES_ACCESS_KEY_ID=your_ses_key
AWS_SES_SECRET_ACCESS_KEY=your_ses_secret
```

### 6. サーバーの起動
```bash
# 開発サーバーの起動
bin/rails server

# または Procfile.dev を使用
bin/dev
```

アプリケーションは http://localhost:3000 でアクセスできます。

## 🧪 テスト

### テストの実行
```bash
# 全てのテストを実行
bin/rails test

# システムテストを実行
bin/rails test:system

# 並列実行を無効にする場合（CI環境など）
PARALLEL_WORKERS=1 bin/rails test
PARALLEL_WORKERS=1 bin/rails test:system
```

### コード品質チェック
```bash
# RuboCop による静的解析
bundle exec rubocop

# セキュリティチェック
bundle exec brakeman
```

## 📦 デプロイ

このプロジェクトは Kamal を使用してデプロイされます。

### 本番環境へのデプロイ
```bash
# 初回デプロイ
kamal setup

# 更新デプロイ
kamal deploy
```

詳細な設定は `config/deploy.yml` を参照してください。

## 🤝 コントリビューション

1. このリポジトリをフォークしてください
2. 機能ブランチを作成してください (`git checkout -b feature/amazing-feature`)
3. 変更をコミットしてください (`git commit -m 'Add some amazing feature'`)
4. ブランチにプッシュしてください (`git push origin feature/amazing-feature`)
5. プルリクエストを作成してください

### コーディング規約
- RuboCop のルールに従ってください
- テストを必ず書いてください
- コミットメッセージは日本語または英語で明確に記述してください

## 📄 ライセンス

このプロジェクトは MIT ライセンスのもとで公開されています。詳細は [LICENSE](LICENSE) ファイルを参照してください。

## 📞 サポート

- **バグ報告**: GitHub Issues を使用してください
- **機能要望**: GitHub Issues でリクエストしてください
- **その他のお問い合わせ**: アプリケーション内のお問い合わせフォームをご利用ください

---

**BrightTalk** - 明るい対話を通じて、アイデアを共有し、コミュニティを築いていきましょう。