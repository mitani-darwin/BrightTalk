# 📝 BrightTalk — README（改訂版）

BrightTalk は、Ruby on Rails 8 と Vite をベースにした  
モダンな Web コンテンツプラットフォームです。  
Markdown エディタ、動画プレイヤー、Passkeyログインなどを統合し、  
開発者・クリエイターが快適に投稿・共有できる環境を提供します。

---

## 🚀 主な特徴

### 📝 投稿・編集機能
- Markdown対応エディタ（CodeMirror 6）
- 画像・動画アップロード（ActiveStorage + S3）
- 自動保存／下書き管理  
- コメント・いいね・カテゴリー分類対応  

### 🎥 メディア対応
- Video.js による動画再生（Stimulusコントローラ制御）
- 複数画像／動画のアップロード対応  
- S3上の動画ストリーミング  

### 🔐 認証・ユーザー管理
- Devise + WebAuthn（Passkey対応）
- ログイン必須でコメント・投稿
- プロフィール編集・アバター設定

### 💬 コメント機能
- 有料コメントは上位表示（`paid: true`）  
- 無料コメントとの差別化（装飾・色変更）  
- ログインユーザーのみ投稿可能  

### 💻 フロントエンド
- **Vite + Stimulus + Turbo**
- CodeMirror 6 ベースの Markdown エディタ
- Flatpickr による日付選択
- Bootstrap 5 + Font Awesome + Bootstrap Icons

### ☁️ インフラ・デプロイ
- Kamal による AWS EC2 / Lightsail デプロイ
- S3 + CloudFront 連携
- SQLite3（軽量構成）または PostgreSQL（本番拡張可）
- CI/CD: GitHub Actions

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
```

### 3️⃣ システム依存関係のインストール
```bash
# macOS
brew install vips
# Ubuntu/Debian
sudo apt install libvips
```

### 4️⃣ データベース設定
```bash
bin/rails db:create
bin/rails db:migrate
bin/rails db:seed
```

### 5️⃣ 環境変数設定（`.env`）
```bash
AWS_ACCESS_KEY_ID=your_key
AWS_SECRET_ACCESS_KEY=your_secret
AWS_REGION=ap-northeast-1
AWS_S3_BUCKET=brighttalk-bucket
```

---

## 🧩 開発サーバー起動

Vite + Rails 両方を統合的に動作させる：
```bash
bin/dev
```

アクセス：  
👉 http://localhost:3000

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
（`package.json` により、各Stimulusコントローラとエディタを個別テスト）

---

## 📦 デプロイ

Kamal を使用してAWSへデプロイ。

```bash
kamal setup   # 初回セットアップ
kamal deploy  # 更新デプロイ
```

設定は `config/deploy.yml` で管理。

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
 │   ├─ application_controller.rb
 │   ├─ comments_controller.rb
 │   └─ video_player_controller.js
 ├─ views/
 │   ├─ layouts/application.html.erb
 │   └─ posts/
 ├─ javascript/
 │   ├─ controllers/
 │   ├─ application.js
 │   └─ stylesheets/
 ├─ models/
 │   ├─ user.rb
 │   ├─ post.rb
 │   └─ comment.rb
config/
 ├─ application.rb
 ├─ environments/
 ├─ deploy.yml
 └─ vite.json
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

- `application.js` → Viteエントリ  
- `Video.js` は Stimulus コントローラ経由で初期化済  
- `ActiveStorage` は direct upload対応  
- `Passkey.js` → WebAuthnロジック全体を管理  
- コメント機能は有料/無料判定を `User#paid?` で制御  
- iOSアプリ（Swift）連携を想定（APIレスポンス整備済）

---

## 💬 Contact

- Author: **darwin2008**
- Repository: [BrightTalk GitHub](https://github.com/mitani-darwin/BrightTalk)
- Issues: GitHub Issues にて受付中

---

✨ **BrightTalk – 明るい対話で、知識と創造をつなぐプラットフォーム。**
