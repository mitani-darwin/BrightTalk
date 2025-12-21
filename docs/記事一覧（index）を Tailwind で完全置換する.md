あなたは Ruby on Rails（Turbo/Hotwire）と Tailwind CSS 4.1 に精通したフロントエンド/UXエンジニアです。
Bootstrap 5 を使っているブログサイトの「記事一覧（index）」ページを、Tailwind CSS 4.1 で“完全置換”してください。

# ゴール（最重要）
- 記事一覧ページ（index）を Tailwind CSS 4.1 のみで実装する
- このページのERB内に Bootstrap クラスを一切含めない（0件）
- Bootstrap はサイト全体では残すが、このページは Tailwind レイアウト（例：layouts/tailwind.html.erb）で表示する
- ブログとして読みやすい余白・行間・タイポグラフィを最優先する
- モバイル→PCまでレスポンシブで崩れない

# 前提（Rails）
- 既存のルーティング/コントローラ/モデルは変更しない（必要なら最小の追記は可）
- 一覧は @posts（ActiveRecord Relation）を使用
- Turboでも破綻しない（GET検索、リンク、ページネーション）
- 既存の属性が不明な箇所は “フォールバック実装” を必ず入れる（後述）

# 対象ファイル（命名が違う可能性があるため、まず候補を列挙してから 1つに決め打ちで実装）
- app/views/posts/index.html.erb
  もしくは（候補例）
  - app/views/articles/index.html.erb
  - app/views/blog/posts/index.html.erb
ただし最終出力は「決め打ちの1つ」に対して、完成コード全文を提示すること。

# 画面要件（ブログ記事一覧）
## 1) ヒーロー/ヘッダー
- ページタイトル（例：記事一覧 / Blog）
- サブテキスト（例：最新の記事を掲載しています）
- 右側（または下）に検索フォーム（任意）
  - GETで q パラメータを送る（例：/posts?q=xxx）
  - 既存検索が無ければUIだけ作り、コメントで「未接続」と明記してOK
- パンくず（任意）：Home / Blog

## 2) 一覧（カード）
- カード形式（ブログっぽい軽さ、管理画面っぽさNG）
- 1カードに含める：
  - タイトル（リンク）
  - 日付（published_at 優先、無ければ created_at）
  - 抜粋（excerpt/summary/body先頭）
  - カテゴリ（あれば）
  - タグ（あれば最大3つ + “+n”）
  - サムネ（あれば表示、無ければプレースホルダ）
- hover/focus-visible を入れる（アクセシブル）
- カードクリック導線は「タイトルリンク」が基本（カード全体リンクは任意）

## 3) レスポンシブ
- モバイル：1カラム
- タブレット：2カラム
- デスクトップ：3カラム
- 右サイドバー（任意）：lg以上のみ表示
  - カテゴリ一覧 / 人気タグ / 検索の補助
  - データが無ければUI枠だけでもOK

## 4) Empty State
- 記事が0件の時
  - 見出し、説明、ボタン（例：トップへ戻る）を表示
  - アイコン不要

## 5) ページネーション
- 下部に配置
- Tailwindで統一された見た目
- kaminari / will_paginate のどちらでも崩れない方針で書く
  - 実装をどちらかに寄せる場合は「寄せた方」と「もう片方の差分」を短く提示

# Tailwind実装ルール（重要）
- Tailwind CSS 4.1 前提のクラスで記述
- Bootstrapクラスを一切使わない
- クラスが長くなる塊は partial に切り出す（必須）
  - app/views/posts/_post_card.html.erb
  - app/views/shared/_pagination.html.erb
  - app/views/shared/_empty_state.html.erb
- 色はニュートラル基調（slate系）＋アクセント1色程度
- 影・境界線は控えめ、余白は広め
- ダークモード対応は任意（入れるなら自然に）

# フォールバック実装（必須）
モデル属性が不明なので、以下のフォールバックで実装すること：
- タイトル：post.title || post.name
- 日付：post.published_at || post.created_at
- 抜粋：
  - post.excerpt || post.summary || strip_tags(post.body.to_s).truncate(140)
- サムネ：
  - ActiveStorageがあれば post.thumbnail / post.image 等を tries し、
    無ければプレースホルダ（グレーの箱）
- カテゴリ/タグ：
  - post.category / post.categories / post.tags など tries して存在すれば表示、無ければ非表示

# 出力形式（必須）
1) 変更/新規作成するファイル一覧（パス付き）
2) 各ファイルの完成コード全文（コピペで動く）
3) 追加した partial の呼び出し関係が分かる説明（短く）
4) 動作確認チェックリスト（10項目程度）
5) Bootstrap禁止ゾーンに違反しない確認方法（grep例1つ）

# 追加要件
- Turbo（Rails標準）で崩れない
- “いかにも管理画面” にならない（ブログらしい余白と文字組）
- 可能ならSEOを意識（h1は1つ、適切な見出し階層）

この条件で、まずは記事一覧（index）を Tailwind で完全に置換し、
必要な partial を作成して、ファイル単位の完成コードを提示してください。docs/記事一覧（index）を Tailwind で完全置換する.md