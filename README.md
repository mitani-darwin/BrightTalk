# BrightTalk

BrightTalkは、ユーザーが投稿を共有し、コメントやいいねで交流できるソーシャルプラットフォームです。Markdownでの投稿作成、画像・動画アップロード、セキュアな認証システムを備えた現代的なWebアプリケーションです。

## 主な機能

### 📝 **投稿・コンテンツ管理**
- **Markdown対応**: Redcarpetを使用したリッチテキスト投稿
- **メディアアップロード**: Active Storageによる画像・動画の管理
- **ドラフト機能**: 投稿の下書き保存と公開管理
- **URL slug**: FriendlyIDによるSEO対応URL
- **投稿タイプ・カテゴリ**: 投稿の分類と整理

### 👤 **ユーザー認証・セキュリティ**
- **Devise認証**: セキュアなユーザー管理
- **WebAuthn/Passkey**: 生体認証・パスワードレス認証
- **メール認証**: 確認メールによる登録システム
- **セキュリティ監査**: Brakernanによる脆弱性チェック

### 💬 **コミュニティ機能**
- **コメントシステム**: 投稿に対するコメント機能
- **いいね機能**: 投稿への評価システム
- **タグ機能**: 投稿のタグ付けと検索
- **ページネーション**: Kaminariによる効率的なページング

### 📱 **UI/UX**
- **レスポンシブデザイン**: モバイル・タブレット対応
- **モダンフロントエンド**: Stimulus + Turbo Rails
- **PDF生成**: Groverによる投稿のPDF出力

## 技術スタック

### バックエンド
- **Ruby**: 3.4.4
- **Rails**: 8.0.2
- **データベース**: SQLite3
- **認証**: Devise + WebAuthn
- **画像処理**: Image Processing, MiniMagick, Active Storage
- **Markdown**: Redcarpet
- **PDF生成**: Grover (Chrome-based)

### フロントエンド
- **JavaScript**: Stimulus, Turbo Rails
- **CSS**: Dart Sass, Tailwind CSS
- **アセット管理**: Propshaft
- **モジュール管理**: Importmap Rails

### インフラ・デプロイメント
- **クラウド**: AWS (ap-northeast-1)
- **コンテナ**: Docker
- **デプロイメント**: Kamal
- **Webサーバー**: Puma + Thruster
- **ストレージ**: AWS S3
- **コンテナレジストリ**: AWS ECR
- **メール配信**: AWS SES

### 開発・運用ツール
- **セキュリティ**: Brakeman
- **コード品質**: RuboCop Rails Omakase
- **テスト**: Capybara, Selenium WebDriver
- **デバッグ**: Debug gem

## セットアップ

### 前提条件

#### 開発環境
- **Ruby**: 3.4.4
- **rbenv**: Ruby バージョン管理 (推奨)
- **Git**: バージョン管理
- **Docker**: コンテナ化 (オプション)
- **ImageMagick**: 画像処理
- **Chrome/Chromium**: PDF生成用

#### 本番環境 (AWS)
- **AWS CLI**: v2.x
- **Terraform**: >= 1.0
- **Docker**: コンテナイメージ作成用

### ローカル開発環境のセットアップ

1. **リポジトリのクローン**
   ```bash
   git clone https://github.com/darwin2008/BrightTalk.git
   cd BrightTalk
   ```

2. **Ruby環境のセットアップ**
   ```bash
   # rbenvを使用する場合
   rbenv install 3.4.4
   rbenv local 3.4.4
   ruby -v  # ruby 3.4.4 が表示されることを確認
   ```

3. **依存関係のインストール**
   ```bash
   bundle install
   ```

4. **データベースのセットアップ**
   ```bash
   rails db:create
   rails db:migrate
   rails db:seed
   ```

5. **開発サーバーの起動**
   ```bash
   bin/dev
   ```

6. **ブラウザでアクセス**
   ```
   http://localhost:3000
   ```

### 開発環境での設定

#### メール配信設定
開発環境では、送信されたメールはコンソールに表示されます。実際のメール配信をテストする場合は、`config/environments/development.rb` でSMTPサーバーの設定を行ってください。

#### 画像アップロード
Active Storageを使用しており、開発環境では `storage/` ディレクトリに画像・動画が保存されます。

#### WebAuthn/Passkey設定
WebAuthn機能を使用するには、HTTPS環境またはlocalhost環境が必要です。開発環境では自動的にlocalhostとして認識されます。

## AWSインフラ構成

### アーキテクチャ概要
- **リージョン**: ap-northeast-1 (東京)
- **VPC**: プライベートネットワーク (10.0.0.0/16)
- **EC2**: t4g.small インスタンス
- **S3**: 画像ストレージ + DBバックアップ
- **ECR**: Dockerイメージリポジトリ
- **SES**: メール配信サービス

### Terraformによるインフラ管理

1. **AWS認証情報の設定**
   ```bash
   aws configure
   ```

2. **Terraformの初期化**
   ```bash
   cd terraform/environments/production
   terraform init
   ```

3. **インフラのプラン確認**
   ```bash
   terraform plan
   ```

4. **インフラの適用**
   ```bash
   terraform apply
   ```

### 主要リソース
- **VPC・ネットワーク**: セキュアなネットワーク環境
- **EC2インスタンス**: アプリケーションサーバー
- **S3バケット**: 
  - `brighttalk-prod-image-production`: 画像ストレージ
  - `brighttalk-prod-image-development`: 開発用画像
  - `brighttalk-db-backup`: データベースバックアップ
- **IAMロール**: EC2からS3へのアクセス権限
- **セキュリティグループ**: ファイアウォール設定

## デプロイメント

### Kamalを使用した本番デプロイ

1. **デプロイ設定の確認**
   ```bash
   # config/deploy.yml を確認・編集
   ```

2. **初回デプロイ**
   ```bash
   kamal setup
   ```

3. **アプリケーションのデプロイ**
   ```bash
   kamal deploy
   ```

4. **デプロイ状況の確認**
   ```bash
   kamal app logs
   kamal app status
   ```

### Docker環境での実行

1. **イメージのビルド**
   ```bash
   docker build -t brighttalk .
   ```

2. **コンテナの実行**
   ```bash
   docker run -p 3000:3000 brighttalk
   ```

## テスト・品質管理

### テスト実行

1. **全テストの実行**
   ```bash
   bundle exec rails test
   ```

2. **システムテスト（E2E）の実行**
   ```bash
   bundle exec rails test:system
   ```

3. **特定のテストファイルの実行**
   ```bash
   bundle exec rails test test/models/post_test.rb
   ```

### コード品質チェック

1. **セキュリティ監査**
   ```bash
   bundle exec brakeman
   ```

2. **コードスタイルチェック**
   ```bash
   bundle exec rubocop
   ```

3. **自動修正**
   ```bash
   bundle exec rubocop -a
   ```

## プロジェクト構造

```
BrightTalk/
├── app/                    # アプリケーションコード
│   ├── controllers/        # コントローラー
│   ├── models/            # モデル
│   ├── views/             # ビューテンプレート
│   ├── helpers/           # ヘルパー
│   ├── assets/            # アセット（CSS, JS, 画像）
│   └── javascript/        # JavaScript（Stimulus）
├── config/                # 設定ファイル
├── db/                    # データベース関連
│   ├── migrate/           # マイグレーションファイル
│   └── seeds.rb          # 初期データ
├── terraform/             # インフラ構成
│   ├── environments/      # 環境別設定
│   └── modules/          # 再利用可能モジュール
├── test/                  # テストファイル
├── Dockerfile            # Docker設定
├── Gemfile               # Ruby依存関係
└── README.md             # このファイル
```

## 環境変数

本番環境で必要な環境変数:

```bash
# データベース
DATABASE_URL=

# AWS設定
AWS_ACCESS_KEY_ID=
AWS_SECRET_ACCESS_KEY=
AWS_REGION=ap-northeast-1

# S3設定
AWS_S3_BUCKET=brighttalk-prod-image-production

# メール設定
MAIL_HOST=
MAIL_USERNAME=
MAIL_PASSWORD=

# アプリケーション設定
SECRET_KEY_BASE=
RAILS_MASTER_KEY=
```

## トラブルシューティング

### よくある問題

1. **ImageMagickエラー**
   ```bash
   # macOS
   brew install imagemagick

   # Ubuntu/Debian
   sudo apt-get install imagemagick
   ```

2. **Chrome/Chromiumが見つからないエラー（PDF生成）**
   ```bash
   # macOS
   brew install --cask google-chrome

   # Ubuntu/Debian
   sudo apt-get install chromium-browser
   ```

3. **WebAuthn/Passkeyが動作しない**
   - HTTPS環境またはlocalhost環境で実行してください
   - ブラウザがWebAuthnをサポートしているか確認してください

## 貢献

1. このリポジトリをフォーク
2. 機能ブランチを作成 (`git checkout -b feature/amazing-feature`)
3. 変更をコミット (`git commit -m 'Add some amazing feature'`)
4. ブランチにプッシュ (`git push origin feature/amazing-feature`)
5. プルリクエストを作成

## ライセンス

このプロジェクトはMITライセンスの下で公開されています。詳細は [LICENSE](LICENSE) ファイルを参照してください。

## 作者

- **darwin2008** - *Initial work* - [GitHub](https://github.com/darwin2008)

## 謝辞

- Ruby on Rails コミュニティ
- すべての依存ライブラリの開発者
- 貢献者の皆様

---

🚀 **BrightTalk** で素晴らしいコンテンツを共有しましょう！
