# BrightTalk

BrightTalkは、ユーザーが投稿を共有し、コメントやいいねで交流できるソーシャルプラットフォームです。

## 主な機能

- 📝 **投稿機能**: テキストと画像の投稿
- 💬 **コメント機能**: 投稿に対するコメント
- ❤️ **いいね機能**: 投稿への評価
- 👤 **ユーザー認証**: Deviseを使用したセキュアな認証
- 📧 **メール認証**: マジックリンクによるワンクリック登録
- 🏷️ **タグ・カテゴリ機能**: 投稿の分類
- 📄 **ページネーション**: Kaminariによる効率的なページング
- 📱 **レスポンシブデザイン**: モバイル対応UI

## 技術スタック

- **Ruby**: 3.4.4
- **Rails**: 8.0.2
- **データベース**: SQLite3 (開発環境)
- **認証**: Devise
- **画像処理**: Image Processing, MiniMagick
- **スタイリング**: Sass Rails
- **JavaScript**: Stimulus, Turbo
- **ページネーション**: Kaminari
- **セキュリティ**: Brakeman
- **PDF生成**: WickedPDF

## セットアップ

### 前提条件

- Ruby 3.4.4
- rbenv (推奨)
- Git

### インストール手順

1. **リポジトリのクローン**
   ```bash
   git clone https://github.com/yourusername/BrightTalk.git
   cd BrightTalk
   ```

2. **Rubyバージョンの確認**
   ```bash
   ruby -v
   # ruby 3.4.4 が表示されることを確認
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

## 開発環境での設定

### メール配信設定

開発環境では、送信されたメールはコンソールに表示されます。実際のメール配信をテストする場合は、`config/environments/development.rb` でSMTPサーバーの設定を行ってください。

### 画像アップロード

Active Storageを使用しており、開発環境では `storage/` ディレクトリに画像が保存されます。

## テスト
