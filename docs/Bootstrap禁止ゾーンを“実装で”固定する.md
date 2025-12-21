あなたは Ruby on Rails（Turbo/Hotwire）と CSS移行（Bootstrap→Tailwind）の実務に精通したテックリードです。
Bootstrap 5 を使っているブログサイトに Tailwind CSS 4.1 を共存導入しつつ、
「Bootstrap禁止ゾーン」を“実装で”固定してください。

# 目的（最重要）
- Bootstrap と Tailwind が同じ画面・同じDOMツリーに混在してカオスになるのを防ぐ
- 「禁止ゾーン＝Tailwind専用ページ」は Bootstrapクラス/Bootstrap JSコンポーネントを使えないように、構造で縛る
- 既存ページ（Bootstrap）は一切崩さない

# 前提
- Rails アプリ（ERBビュー）
- 既に Bootstrap 5 が application.css / application.scss 経由で使われている
- Tailwind CSS 4.1 を tailwindcss-rails で導入予定（または導入済み）
- まずは “ページ単位” で Tailwind 化していく
- 本番運用中なので破壊的変更は禁止

# やること（実装タスク）

## Task A: Tailwind専用レイアウトを作る（Bootstrapと分離）
- 新規ファイル：app/views/layouts/tailwind.html.erb を作成
- ここでは Tailwind のみを読み込み、Bootstrap を読み込まない
  - 既存の application レイアウトは Bootstrap 維持（変更最小）
- body タグに識別子を付与する（例：data-ui="tw" と class="ui-tw"）
- Turbo に配慮（csrf_meta_tags, csp_meta_tag, javascript_importmap_tags 等を維持）
- サイト共通の head（title, meta, favicon 等）も破綻しないようにする

## Task B: Tailwind専用コントローラ基底を作る（禁止ゾーンの入口）
- 新規：app/controllers/tailwind/base_controller.rb
- ここで layout "tailwind" を強制する
- 将来の Tailwind ページは必ずこの BaseController を継承する運用にする
- 例として PostsController の index だけ Tailwind レイアウトに切り替える案も提示する（方法は2通り出す）
  1) controller全体をTailwind化（継承差し替え）
  2) action単位で layout を切り替え（layout -> 例: layout "tailwind", only: [:index]）

## Task C: 禁止ゾーンを機械的に検出する（軽量でOK）
- ripgrep などで「禁止ゾーン配下のERBにBootstrapクラスが混入していないか」検出するコマンドを作る
- 対象は以下のいずれかで設計してよい（より安全な方を採用）：
  - 方式1：Tailwind専用ビューを app/views/tw/... にまとめる
  - 方式2：ファイル名サフィックスで区別（例：*.tw.html.erb）
- Bootstrapクラス検出パターン例：
  - "container", "row", "col-", "btn", "card", "dropdown", "modal", "alert", "badge", "d-flex", "text-" など
- scripts/check_no_bootstrap_in_tw.sh を新規作成し、コマンド全文を提示
- 可能なら bin/ci か GitHub Actions で呼べる形の提案もする（任意）

## Task D: 例外（移行中ゾーン）の逃げ道を用意
- 「本文（記事詳細）」のように、既存HTMLスタイルを保ちたい領域は “移行中ゾーン” として例外扱いが必要
- 例外を許可する条件をコードコメントとdocsに落とし込む
- 例外領域は data-ui="legacy" などの属性で明示し、禁止ゾーンと混ざらない設計にする

# 重要な制約（絶対）
- 既存Bootstrapページは変更最小（壊さない）
- Tailwind禁止ゾーン（tailwindレイアウト）では Bootstrap を読み込まない
- Tailwind禁止ゾーン内で Bootstrapクラスは使わない（検出スクリプトで担保）
- 出力は“コピペで導入できる”レベルの完成コードにする

# 成果物（必須出力）
1) 変更/新規作成するファイル一覧（パス付き）
2) 各ファイルの完成コード全文
   - app/views/layouts/tailwind.html.erb
   - app/controllers/tailwind/base_controller.rb
   - scripts/check_no_bootstrap_in_tw.sh
   - （必要なら）例として変更する controller/view の差分
3) 導入手順（実行コマンド、どこに何を置くか）
4) 動作確認チェックリスト（10項目前後）

さあ、上記の要件を満たす実装案を、ファイル単位の完成コードで提示してください。