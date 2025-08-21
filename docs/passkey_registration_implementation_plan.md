# パスキー登録実装計画

## 概要
現在のパスワード必須のユーザー登録システムを、パスキー登録に変更する実装計画

## 現状分析

### ✅ 既存の実装状況
- **データベース**: `webauthn_credentials`テーブル存在
- **JavaScript**: `passkey.js`で完全なWebAuthn API実装済み
- **コントローラー**: `PasskeySessionsController`でログイン処理済み
- **Devise**: 標準的な認証システム稼働中

### ❌ 不足している実装
- **webauthn gem**: Gemfileに未追加
- **WebauthnCredentialモデル**: モデルファイル不存在
- **登録フロー**: パスワードからパスキーへの変更
- **コントローラー**: パスキー登録用エンドポイント

## 実装方針

### 段階的移行アプローチ
1. **フェーズ1**: パスキー必須登録の実装
2. **フェーズ2**: 既存ユーザーのパスキー移行促進
3. **フェーズ3**: パスワード認証の段階的廃止

## 詳細実装計画

### 1. 基盤整備

#### 1.1 webauthn gem追加
```ruby
# Gemfile
gem 'webauthn', '~> 3.0'
```

#### 1.2 WebauthnCredentialモデル作成
```ruby
# app/models/webauthn_credential.rb
class WebauthnCredential < ApplicationRecord
  belongs_to :user
  
  validates :external_id, presence: true, uniqueness: true
  validates :public_key, presence: true
  validates :nickname, presence: true
  
  scope :active, -> { where('last_used_at IS NULL OR last_used_at > ?', 30.days.ago) }
end
```

#### 1.3 Userモデルの更新
```ruby
# app/models/user.rb に追加
has_many :webauthn_credentials, dependent: :destroy
alias_method :passkeys, :webauthn_credentials

def has_passkeys?
  webauthn_credentials.exists?
end

def password_required?
  # パスキーが登録されていない場合のみパスワード必須
  !persisted? || (!password.nil? || !password_confirmation.nil?) && !has_passkeys?
end
```

### 2. コントローラー実装

#### 2.1 PasskeyRegistrationController作成
```ruby
# app/controllers/passkey_registrations_controller.rb
class PasskeyRegistrationsController < ApplicationController
  def new
    @user = User.new
  end

  def create
    @user = User.new(user_params)
    @user.password = SecureRandom.hex(16)  # 一時パスワード生成
    
    if @user.save
      session[:pending_user_id] = @user.id
      render json: { success: true, user_id: @user.id }
    else
      render json: { errors: @user.errors.full_messages }, status: :unprocessable_entity
    end
  end

  def register_passkey
    # パスキー登録のチャレンジ生成
    # WebAuthn::Credential.options_for_create使用
  end

  def verify_passkey
    # パスキー登録の検証
    # WebAuthn::Credential.from_create使用
  end

  private

  def user_params
    params.require(:user).permit(:name, :email)
  end
end
```

#### 2.2 ルーティング追加
```ruby
# config/routes/auth.rb
Rails.application.routes.draw do
  devise_for :users, controllers: {
    registrations: 'users/registrations',
    confirmations: 'users/confirmations'
  }
  
  # パスキー登録用
  resources :passkey_registrations, only: [:new, :create] do
    collection do
      post :register_passkey
      post :verify_passkey
    end
  end
end
```

### 3. フロントエンド実装

#### 3.1 新規登録フォームの更新
```html
<!-- app/views/passkey_registrations/new.html.erb -->
<div class="registration-flow">
  <!-- ステップ1: 基本情報入力 -->
  <div id="basic-info-step" class="step active">
    <h4>基本情報の入力</h4>
    <%= form_with model: @user, url: passkey_registrations_path, id: 'basic-info-form' do |f| %>
      <%= f.text_field :name, placeholder: "名前" %>
      <%= f.email_field :email, placeholder: "メールアドレス" %>
      <%= f.submit "次へ：パスキーを設定", class: "btn btn-primary" %>
    <% end %>
  </div>
  
  <!-- ステップ2: パスキー登録 -->
  <div id="passkey-setup-step" class="step hidden">
    <h4>パスキーの設定</h4>
    <p>生体認証またはセキュリティキーでアカウントを保護します</p>
    <button id="setup-passkey-btn" class="btn btn-success">パスキーを設定</button>
  </div>
  
  <!-- ステップ3: 完了 -->
  <div id="completion-step" class="step hidden">
    <h4>登録完了</h4>
    <p>パスキー認証が正常に設定されました</p>
  </div>
</div>
```

#### 3.2 JavaScript統合
```javascript
// app/javascript/registration_flow.js
class PasskeyRegistrationFlow {
  constructor() {
    this.initializeEventListeners();
  }

  async handleBasicInfoSubmission(event) {
    event.preventDefault();
    
    const formData = new FormData(event.target);
    const response = await fetch('/passkey_registrations', {
      method: 'POST',
      body: formData,
      headers: {
        'X-CSRF-Token': document.querySelector('[name="csrf-token"]').content
      }
    });
    
    if (response.ok) {
      this.showPasskeySetup();
    } else {
      this.showErrors(await response.json());
    }
  }

  async setupPasskey() {
    try {
      // チャレンジ取得
      const challengeResponse = await fetch('/passkey_registrations/register_passkey', {
        method: 'POST'
      });
      const options = await challengeResponse.json();
      
      // パスキー登録実行
      const credential = await startPasskeyRegistration(options.publicKey);
      
      // 登録完了
      this.showCompletion();
      
    } catch (error) {
      console.error('パスキー登録エラー:', error);
      this.showError(error.message);
    }
  }
}
```

### 4. セキュリティ対策

#### 4.1 一時パスワードの無効化
- パスキー登録完了後、一時パスワードを削除
- データベースのencrypted_passwordフィールドをnullに設定

#### 4.2 フォールバック認証
- 管理者用の緊急アクセス手段確保
- メール認証によるアカウント復旧機能

### 5. 移行計画

#### 5.1 既存ユーザーへの通知
- ログイン時にパスキー設定を促すバナー表示
- メール通知による移行案内

#### 5.2 段階的パスワード廃止
1. **Week 1-2**: 新規ユーザーのパスキー必須化
2. **Week 3-4**: 既存ユーザーへの移行促進
3. **Week 5-8**: パスワードログインの段階的制限
4. **Week 9+**: 完全パスキー移行

## 実装優先度

### 🔥 高優先度（即座に実装）
1. webauthn gem追加
2. WebauthnCredentialモデル作成
3. 基本的な登録フロー実装

### 🔶 中優先度（1週間以内）
1. UI/UXの改良
2. エラーハンドリング強化
3. セキュリティ機能追加

### 🔵 低優先度（2週間以内）
1. 既存ユーザー移行機能
2. 管理画面対応
3. 詳細な監査ログ

## 期待される効果

### セキュリティ向上
- フィッシング攻撃への耐性
- パスワード漏洩リスクの排除
- 強固な多要素認証

### ユーザビリティ向上
- パスワード記憶の負担軽減
- 高速なログイン体験
- デバイス間でのシームレス認証

### 運用負荷軽減
- パスワードリセット対応の削減
- セキュリティインシデントの減少
- ユーザーサポートの効率化