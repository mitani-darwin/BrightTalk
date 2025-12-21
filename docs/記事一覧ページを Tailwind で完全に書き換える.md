あなたは Ruby on Rails + Tailwind CSS 4.1 に精通したUI/フロントエンドエンジニアです。
Bootstrap 5 を使っているブログの「記事一覧ページ」を、Tailwind CSS 4.1 で“完全に”書き換えてください。

# 目的
- 記事一覧ページ（index）を Tailwind 4.1 のみで実装する
- 既存の Bootstrap 5 はサイト全体では残すが、この記事一覧ページでは使わない（Bootstrapクラスを出さない）
- ブログとして読みやすい余白・行間・タイポグラフィを最優先する
- モバイル→PCまでレスポンシブで崩れないこと

# 前提（Rails）
- 既存のルーティングやコントローラ/モデルは変更しない（必要なら最小の追加は可）
- 既存の @posts（ActiveRecord Relation）を使う想定で実装する
- 既存のページネーション（kaminari / will_paginate 等）がある前提で、どちらでも動くように分岐実装するか、抽象化して書く
- 既存の部分テンプレがあれば極力活用、なければ新規で partial 化する

# 対象ページ
- app/views/posts/index.html.erb （もし命名が違いそうなら候補を列挙し、どれに適用するか決め打ちで1つ提示）
- 必要なら以下も新規作成してよい（必ずファイルパスを明示する）
  - app/views/posts/_post_card.html.erb
  - app/views/shared/_pagination.html.erb
  - app/views/shared/_empty_state.html.erb
  - app/helpers/posts_helper.rb（必要なら）

# 画面要件（ブログ記事一覧）
1) ヘッダー
- ページタイトル（例：記事一覧）
- サブテキスト（例：最新の記事を掲載しています）
- 右側に検索フォーム（任意：qパラメータ）を配置（GET、Turboでも動く）
  - 検索が難しければ UI だけ作り「未接続」とコメントしてOK

2) 一覧表示
- カード形式で表示（サムネがあれば上/左、なければプレースホルダ）
- 各カードに含める要素：
  - タイトル（リンク）
  - 抜粋（excerpt / summary / bodyの先頭など。なければ省略でもOK）
  - 投稿日（created_at / published_at 優先）
  - カテゴリ（あれば）
  - タグ（あれば、最大3つ＋“+n”）
- hover/focus のアクセシブルな見た目を入れる
- 行間・余白は「読みやすさ重視」（密すぎない）

3) レスポンシブ
- モバイル：1カラム
- タブレット：2カラム
- デスクトップ：3カラム
- サイドバー（任意）：PCのみ表示（カテゴリ一覧・人気タグ等。データが無ければUIだけでもOK）

4) Empty State
- 記事が0件のときの表示を作る（アイコン不要、テキストとボタンでOK）

5) ページネーション
- 下部に配置
- Tailwindで見た目を統一
- kaminari / will_paginate のどちらでも破綻しない実装を意識
  - どうしてもどちらかに寄せる場合は「どちらに寄せたか」を明記し、もう片方の差分案も短く書く

# Tailwind実装ルール（重要）
- Tailwind CSS 4.1 前提のクラスで記述する
- Bootstrapクラスを一切使わない
- クラスの長文化を避けるため、再利用する塊は partial 化する
- 色はニュートラル基調（例：slate系）＋アクセント1色程度
- ダークモード対応は任意（入れるなら自然に）
- a11y：見出し階層、リンクのfocus-visible、ボタンのaria-label等を意識する

# 出力形式（必須）
1) 変更/新規作成するファイル一覧（パス付き）
2) 各ファイルの完成コード全文（コピペで動く状態）
3) 既存のモデル属性が不明な箇所は、以下の「フォールバック実装」を入れること：
   - タイトル：post.title || post.name
   - 日付：post.published_at || post.created_at
   - 抜粋：post.excerpt || post.summary || strip_tags(post.body).truncate(140)
   - サムネ：post.thumbnail_url / post.image / ActiveStorage のどれかがあれば表示、無ければプレースホルダ
4) 動作確認チェックリスト（5〜10項目）

# 追加の品質要件
- Turbo（Rails標準）で崩れない
- 余白/文字サイズ/行間がブログとして自然（読み物に最適化）
- “いかにも管理画面” にならない（ブログらしい軽さ）

さあ、まずは「app/views/posts/index.html.erb」を Tailwind で完成させ、
必要な partial を切り出して、全コードを提示してください。