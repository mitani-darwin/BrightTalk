あなたは Ruby on Rails（Turbo/Hotwire）と Tailwind CSS 4.1、
およびブログ向けタイポグラフィ設計に精通したフロントエンドエンジニアです。

Bootstrap 5 を使用しているブログサイトの
「記事詳細ページ（show）」を、
Tailwind CSS 4.1 + Tailwind Typography（prose）前提で
“完全に置換”してください。

# ゴール（最重要）
- 記事詳細ページを Tailwind CSS 4.1 のみで実装する
- 記事本文は Tailwind Typography（prose）を前提とする
- このページ内に Bootstrap クラスを一切含めない（0件）
- Bootstrap はサイト全体では残すが、このページは Tailwind 専用レイアウトで表示する
- 長文が「とにかく読みやすい」ことを最優先する

# 前提（Rails）
- 既存のルーティング / Controller / Model は変更しない
- 記事は @post（ActiveRecord オブジェクト）で取得済み
- 記事本文は以下のいずれかで提供される想定：
  - HTML（rawで出力）
  - Markdown → HTML 変換済み
- Turbo（リンク遷移 / 戻る）で破綻しない
- Tailwind Typography プラグインは使用可能とする

# 対象ファイル
- app/views/posts/show.html.erb
  （命名が異なる場合は候補を列挙し、最終的に1つに決め打ちで実装すること）

# 画面構成要件

## 1) 記事ヘッダー（本文より前）
- 記事タイトル（h1・ページ内で1つだけ）
- メタ情報
  - 公開日（published_at 優先、なければ created_at）
  - カテゴリ（あれば）
  - タグ（あれば）
- 必要以上に装飾しない（静か・読み物優先）
- モバイルでも詰まらない余白設計

## 2) 記事本文（最重要）
- article タグで囲む
- prose クラスを使用する
  - prose-base または prose-lg を基準
  - max-w-* を指定し、行の長さを制御
- 対象要素：
  - p / h2 / h3
  - ul / ol
  - blockquote
  - pre / code
  - a
  - img（あれば）
- 行間・段落間余白を広めに取り、可読性最優先

## 3) 記事フッター
- タグ一覧（再掲）
- 前後記事ナビゲーション（あれば）
  - 「← 前の記事」「次の記事 →」
- SNSボタンなどは入れても控えめ（任意）

## 4) サイド要素（任意）
- lg以上でのみ表示
- カテゴリ一覧 / 最新記事 / 著者情報など
- 本文の可読性を邪魔しない配置

## 5) Empty / Error 考慮
- 記事本文が空の場合のフォールバック表示
- nil チェックを丁寧に行う

# Tailwind実装ルール（厳守）
- Tailwind CSS 4.1 のクラスのみ使用
- Bootstrapクラスを一切使わない
- prose 内で utility を無理に上書きしすぎない
- 色は slate 系 + アクセント1色まで
- 影・罫線・アニメーションは最小限
- a11y を意識（見出し階層、link focus-visible）

# フォールバック実装（必須）
モデル属性が不明なため、以下のフォールバックを必ず入れる：

- タイトル：
  post.title || post.name

- 日付：
  post.published_at || post.created_at

- 本文：
  post.body_html || post.body || post.content

- カテゴリ：
  post.category || post.categories.first（存在すれば）

- タグ：
  post.tags（存在すれば）

# 出力形式（必須）
1) 変更/新規作成するファイル一覧（パス付き）
2) app/views/posts/show.html.erb の完成コード全文
3) prose 設計の意図（短く：なぜこのサイズ/余白か）
4) 動作確認チェックリスト（10項目前後）
5) Bootstrap禁止ゾーンに違反していないことの確認方法（grep例）

# 追加品質要件
- h1は1ページに1つだけ
- SEOを意識した見出し構造
- “管理画面っぽさ” を完全に排除
- 「読む」ことに集中できるUI

この条件で、
記事詳細ページ（show）を
Tailwind CSS 4.1 + prose 前提で完全に置換し、
コピペで使える完成コードを提示してください。