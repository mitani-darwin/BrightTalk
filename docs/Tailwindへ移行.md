あなたは Ruby on Rails に精通したフロントエンド / UI 設計の専門家です。

以下の条件を必ず守りながら、
Bootstrap 5 を使用しているブログサイトを
Tailwind CSS 4.1 に「段階的・安全に」移行してください。

# 前提条件
- サイト種別：ブログサイト
- フレームワーク：Ruby on Rails
- 現在のCSS：Bootstrap 5
- 目標CSS：Tailwind CSS 4.1
- 既存の記事本文（HTML / Markdown）は崩さないこと
- 本番運用中のサイトであるため、破壊的変更は禁止

# 移行方針（絶対遵守）
1. Bootstrap は即削除しない
2. Tailwind は Bootstrap と「共存」させる
3. Tailwind は以下の UI 要素から適用する
   - ヘッダー / ナビゲーション
   - 記事一覧（カードUI）
   - サイドバー（カテゴリ・タグ）
   - フッター
4. 記事本文エリアには最初は Tailwind を適用しない
5. Tailwind の preflight（CSSリセット）が
   記事本文に影響しないように設計すること

# 実装タスク

## Step 1. Tailwind CSS 4.1 を Rails に導入
- tailwindcss-rails を使用する
- 生成されるファイル構成を明示する
- Bootstrap の既存設定は変更しない

## Step 2. Bootstrap と Tailwind の共存設定
- application.css / application.scss は Bootstrap 維持
- Tailwind 用の stylesheet を分離
- Tailwind を適用する HTML 範囲を限定する設計にする

## Step 3. レイアウト設計
- Bootstrap 用レイアウトと
  Tailwind 用レイアウトを分ける
- Tailwind 用レイアウトでは
  body 直下に Tailwind クラスを適用する

## Step 4. UIコンポーネントの移行
以下の Bootstrap UI を Tailwind に書き換える：
- ナビゲーションバー
- 記事一覧カード
- ページネーション
- タグ / カテゴリ表示

それぞれについて：
- Bootstrap のクラス例
- Tailwind 4.1 での実装例
を対比して示すこと

## Step 5. 記事本文の最終移行（オプション）
- Tailwind Typography（prose）を使った場合の実装例を示す
- 記事本文を prose に移行するメリットと注意点を説明する
- 既存記事に影響が出ない段階移行手順を明示する

# 成果物として出力するもの
1. 導入手順（コマンド付き）
2. レイアウト構成例（Rails）
3. Bootstrap → Tailwind の対応表（ブログ向け）
4. 記事一覧・カードUIの Tailwind 実装例
5. 事故を防ぐためのチェックリスト

# 重要
- Tailwind CSS 4.1 の書き方に準拠すること
- utility class の乱用は避け、読みやすさを重視する
- ブログの可読性・余白・行間を最優先する