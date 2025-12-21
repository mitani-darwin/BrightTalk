あなたは Ruby on Rails のフロントエンド設計と、大規模なCSS移行（Bootstrap→Tailwind）の実務に精通したテックリードです。
既存ブログサイト（現在 Bootstrap 5 使用）を Tailwind CSS 4.1 に段階移行するために、
「Bootstrap禁止ゾーン（Bootstrapクラス/コンポーネントを使ってはいけない領域）」を定義するルール文書を作成してください。

# 目的
- Bootstrap と Tailwind を共存させつつ、混在地獄（両方のクラスが同一画面に混ざる状態）を防ぐ
- チーム/将来の自分が迷わず実装できる “境界線” を明文化する
- PRレビュー基準として使えるレベルにする

# 前提
- Rails（Turbo/Hotwireあり）
- 現在：Bootstrap 5 が application.css/application.scss で読み込まれている
- 目標：Tailwind CSS 4.1 を導入し、画面単位で順次移行する
- 本番運用中のため、一括置換はしない

# 文書の出力先
- docs/frontend/bootstrap_ban_zones.md（このパスで作る前提で書く）
- 併せて docs/frontend/README.md に追記する場合の追記例も提示する（任意）

# 文書に必ず含める内容（章立て）
1. 概要：なぜ禁止ゾーンが必要か（混在の具体的事故例も短く）
2. 用語定義：
   - Bootstrap許可ゾーン / 禁止ゾーン / 移行中ゾーン（例外扱い）など
3. 禁止ゾーンの基本ルール（Must / Must Not）
   - 禁止：Bootstrapクラス（例：container, row, col, btn, card, text-*, d-flex...）
   - 禁止：Bootstrap JS依存コンポーネント（modal, dropdown など）
   - 許可：Tailwindクラス、Tailwindコンポーネント、必要なら最小のカスタムCSS
4. 禁止ゾーンの指定方法（Railsでの実装規約）
   - レイアウト分離（例：application.html.erb はBootstrap、tailwind.html.erb はTailwind）
   - コントローラで layout を切り替える例
   - body への識別クラス（例：data-ui="tw" / class="ui-tw"）規約
   - ビュー/partial命名規約（例：_post_card.tw.html.erb のような区別案も可）
5. 「画面単位」の禁止ゾーン定義（具体例）
   - 記事一覧：禁止
   - 記事詳細：本文は移行中（例外）、周辺UIは禁止
   - ヘッダー/フッター：禁止（または移行中→禁止へ）
   - 既存の古いページ：許可（凍結）
   ※このあたりはブログ向けに合理的な提案を行い、表で整理する
6. 例外ポリシー（移行中ゾーン）
   - 例外を許す条件（期限/チケット必須/範囲限定）
   - 例外申請テンプレ（PR本文に貼るテンプレ）
7. コードレビューのチェック項目（コピペ可能）
   - 「禁止ゾーンにBootstrapクラスが入っていないか」
   - 「禁止ゾーンに bootstrap JS コンポーネントを入れていないか」
   - 「Tailwindのpreflightが本文に影響していないか」等
8. 自動検知（任意だができれば入れる）
   - grep / ripgrep で Bootstrapクラスを検出する簡易スクリプト例
   - CI（GitHub Actions）で docs/frontend/bootstrap_ban_zones.md のルールを守るためのコマンド例
   - ただし過度に複雑にしない
9. よくある質問（FAQ）
   - 「Bootstrapのgridだけ使って良い？」→原則NG、例外条件
   - 「既存partialにTailwindを足して良い？」→ゾーン判定次第
   - 「本文（Markdown/HTML）はどうする？」→移行中ゾーンの扱い
10. 移行の完了条件（Bootstrap削除の判断基準）

# 出力形式
- Markdownで、見出しと箇条書きを多用して読みやすく
- “Must / Should / May” の表現で強度を明確に
- 具体例（Railsのファイルパス/コード断片）を入れる
- そのまま docs に置ける完成文として出力する

この条件で、docs/frontend/bootstrap_ban_zones.md の完成版を提示してください。