# Bootstrap禁止ゾーン運用ルール

## 1. 概要
BootstrapとTailwindを同一画面で混在させると、見た目と挙動の不整合が起きやすくなります。禁止ゾーンを定義することで「どこまでがTailwind専用か」を明確にし、移行の安全性と速度を両立させます。

### 混在の具体的事故例
- `btn` と `rounded-xl` が混在し、ボタンのサイズやホバーがページ内でバラつく
- Bootstrapの`row/col`とTailwindの`grid`が競合して、レスポンシブで崩れる
- BootstrapのJS（modal/dropdown）がTailwind側に入り込み、Turbo遷移後に二重初期化される

## 2. 用語定義
- **Bootstrap許可ゾーン**: 既存画面。Bootstrapクラスとコンポーネント使用を許可する領域
- **Bootstrap禁止ゾーン**: Tailwind専用画面。Bootstrapクラス/JSコンポーネントを禁止する領域
- **移行中ゾーン**: 本文など影響範囲が大きく段階移行中の領域。例外ルールを適用

## 3. 禁止ゾーンの基本ルール（Must / Must Not）
- **Must**: Tailwindユーティリティ、Tailwindコンポーネント、必要最小限のカスタムCSSのみを使う
- **Must Not**: Bootstrapクラスを一切使わない
  - 例: `container`, `row`, `col-*`, `btn`, `card`, `text-*`, `d-flex`, `mb-*`, `alert`, `badge`
- **Must Not**: BootstrapのJS依存コンポーネントを使わない
  - 例: `modal`, `dropdown`, `collapse`, `tooltip`, `toast`
- **Should**: `focus-visible` を含むアクセシブルなフォーカスを維持
- **Should**: 可読性優先の余白・行間（ブログの読み物として自然）
- **May**: Tailwindで表現しづらい場合のみ最小限のカスタムCSSを許可

## 4. 禁止ゾーンの指定方法（Rails実装規約）
### 4.1 レイアウト分離
- Bootstrap: `app/views/layouts/application.html.erb`
- Tailwind: `app/views/layouts/tailwind.html.erb`

```erb
<!-- app/views/layouts/tailwind.html.erb -->
<body class="tw">
  <%= yield %>
</body>
```

### 4.2 コントローラでレイアウト切り替え
```ruby
# app/controllers/posts_controller.rb
class PostsController < ApplicationController
  layout "tailwind", only: [:index]
end
```

### 4.3 bodyへの識別クラス/属性
- **Must**: Tailwind専用レイアウトでは `class="tw"` など明示的な識別子を付ける
- **Should**: `data-ui="tw"` など追加識別子を併用しても良い

### 4.4 ビュー/partial命名規約
- **Should**: 禁止ゾーン専用部分は `app/views/posts/_post_card.html.erb` のように切り出す
- **May**: 明確化のため `*_tw.html.erb` の命名規則を採用してもよい

## 5. 画面単位の禁止ゾーン定義（例）
| 画面/領域 | ゾーン | 理由/補足 |
| --- | --- | --- |
| 記事一覧（`posts#index`） | 禁止 | Tailwind完全移行済み。Bootstrapクラスは禁止 |
| 記事詳細の本文 | 移行中 | Markdown/HTMLの影響が大きいため例外運用 |
| 記事詳細の周辺UI（タグ/カテゴリ/関連投稿） | 禁止 | Tailwindへ先行移行しやすい |
| ヘッダー/フッター | 禁止 | 共通UIとしてTailwindへ移行しやすい |
| 既存の古いページ（未着手） | 許可（凍結） | 触らない限りBootstrap維持 |

## 6. 例外ポリシー（移行中ゾーン）
- **Must**: 例外は期限とチケットを必須とする
- **Must**: 例外範囲を最小に限定する（本文など限定範囲のみ）
- **Should**: 移行中ゾーンの終点（Tailwind化の完了条件）を明記する

### 例外申請テンプレ（PR本文に貼る）
```
## Bootstrap例外申請
- 対象ファイル/範囲:
- 例外理由:
- 期限（移行完了予定日）:
- チケット/Issue:
- 影響範囲とロールバック手順:
```

## 7. コードレビューのチェック項目（コピペ可）
- [ ] 禁止ゾーンにBootstrapクラスが入っていないか
- [ ] 禁止ゾーンにBootstrap JSコンポーネントが入っていないか
- [ ] Tailwindのpreflightが本文に影響していないか
- [ ] `focus-visible` などのアクセシビリティが保たれているか
- [ ] 画面単位のゾーン定義に反していないか

## 8. 自動検知（簡易スクリプト例）
### 8.1 ripgrep例（禁止クラス検知）
```sh
rg -n "\b(container|row|col-|btn|card|text-|d-flex|alert|badge)\b" app/views/posts app/views/shared
```

### 8.2 CIでの例（GitHub Actionsのstep例）
```yaml
- name: Bootstrap禁止ゾーンの簡易チェック
  run: rg -n "\b(container|row|col-|btn|card|text-|d-flex|alert|badge)\b" app/views/posts app/views/shared
```

## 9. FAQ
**Q. Bootstrapのgridだけ使って良い？**
- 原則NG。どうしても必要なら移行中ゾーンとして期限とチケットを明記する。

**Q. 既存partialにTailwindを足して良い？**
- ゾーン判定次第。禁止ゾーン側にあるpartialはTailwindのみで記述する。

**Q. 本文（Markdown/HTML）はどうする？**
- 本文は移行中ゾーンとして扱い、preflight無効化や`prose`導入は段階的に実施する。

## 10. 移行の完了条件
- 主要画面の禁止ゾーン化が完了している
- Bootstrap依存のJSコンポーネントが残っていない
- Bootstrapクラスが新規追加されていない
- 例外申請の残件が0件
- 本文の表示品質がTailwindベースで安定している

## README追記例（任意）
```md
## Bootstrap禁止ゾーン
Tailwind移行中は `docs/frontend/bootstrap_ban_zones.md` を参照し、禁止ゾーンではBootstrapクラスを使わないこと。
```
