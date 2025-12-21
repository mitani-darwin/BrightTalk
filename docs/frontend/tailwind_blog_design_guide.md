# Tailwindブログデザインガイド

## 1. このガイドの位置づけ（Must）
- 本ガイドはブログUIの**一次情報**であり、今後の実装・レビューの基準となる
- 参照タイミング: 新規画面の設計、既存改修、PRレビュー時
- Tailwind公式Docsは「機能の辞書」、本ガイドは「実務の基準」

## 2. デザイン思想（Why）
- ブログUIの最優先は**可読性**。読み疲れを防ぐために「余白」と「行間」を数値で固定する
- 余白と文字サイズを厳密に決めることで、迷いとブレを排除する
- Bootstrapの汎用UIと違い、読み物に最適化された静かなレイアウトを目指す

## 3. レイアウト基準（Must）
- 記事本文の最大幅:
  - `max-w-prose` または `max-w-[720px]`
- 一覧ページの最大幅:
  - `max-w-screen-xl`
- 中央寄せの原則:
  - `mx-auto` を基本にする
- 左右padding指針（ブレークポイント別）:
  - mobile: `px-4`
  - tablet: `sm:px-6`
  - desktop: `lg:px-10`

## 4. 文字サイズ・行間ルール（最重要・Must）
- body基本文字サイズ:
  - `text-base` を標準（モバイルでも下げない）
- 行間の基準:
  - 本文: `leading-7`
  - 抜粋: `leading-relaxed`
- 見出し（h1〜h4）:
  - h1: `text-3xl md:text-4xl leading-tight font-semibold`
  - h2: `text-2xl md:text-3xl leading-snug font-semibold`
  - h3: `text-xl md:text-2xl leading-snug font-semibold`
  - h4: `text-lg md:text-xl leading-snug font-semibold`
- 見出しの上下余白:
  - `mt-10 mb-4` を基本
- モバイルで文字を小さくしすぎないこと

## 5. 記事本文（prose）の設計指針（Must）
- Tailwind Typographyを使う場合:
  - `prose prose-slate max-w-none`
  - `prose-p:leading-7 prose-headings:scroll-mt-24`
- proseを使わない場合:
  - 本文: `text-base leading-7 text-slate-700`
- 余白基準:
  - 段落: `mb-5`
  - リスト: `my-4 pl-6`
  - 引用: `my-6 border-l-4 border-slate-200 pl-4 text-slate-600`
  - コードブロック: `my-6 rounded-lg bg-slate-950/90 p-4 text-slate-100`
- 1行あたりの文字数目安:
  - 35〜40文字

## 6. 記事一覧・カードUIの余白ルール（Should）
- カード内余白: `p-5`
- カード間隔: `gap-6`
- タイトル・メタ・抜粋の間隔:
  - `space-y-2` と `gap-4` を基本
- hover時の変化は控えめ:
  - `hover:shadow-md` / `hover:-translate-y-0.5` 程度

## 7. 色・コントラストの基本ルール（Should）
- 基本文字色: `text-slate-700`
- 見出し色: `text-slate-900`
- 背景色: `bg-white` と `bg-slate-50` のみ
- アクセントカラーは1色に抑える
- NG例:
  - `text-slate-300` を本文に使う（コントラスト不足）
  - アクセント色を複数使う（派手になりすぎ）

## 8. レスポンシブ設計の考え方（Must）
- モバイルファーストで余白を設計する
- 変えてよいもの:
  - カラム数、カードの並び、余白
- 変えないもの:
  - 本文の文字サイズ、本文の行間
- 文字サイズをレスポンシブで変えすぎない

## 9. Tailwindクラス早見表（実務向け・Must）
| 用途 | 推奨クラス |
| --- | --- |
| 記事本文 | `text-base leading-7 text-slate-700` |
| 記事タイトル | `text-2xl font-semibold leading-tight` |
| 抜粋 | `text-sm text-slate-600 leading-relaxed` |
| メタ情報 | `text-xs text-slate-500` |
| カード余白 | `p-5` |
| カード間隔 | `gap-6` |

### NGパターン
- 本文に `text-xs` を使う
- 本文に `leading-tight` を使う
- `p-2` のように余白を削りすぎる

## 10. 実装例（Railsビュー・コピペ可）
### 記事本文（article）
```erb
<article class="prose prose-slate max-w-none">
  <%= @post.content_as_html %>
</article>
```

### 記事一覧カード
```erb
<article class="rounded-2xl border border-slate-200 bg-white p-5 shadow-sm">
  <h2 class="text-xl font-semibold leading-snug text-slate-900">タイトル</h2>
  <p class="mt-2 text-sm leading-relaxed text-slate-600">抜粋テキスト...</p>
</article>
```

### サイドバー見出し
```erb
<h2 class="text-sm font-semibold uppercase tracking-widest text-slate-500">カテゴリー</h2>
```

## 11. 運用ルール（Must）
- 新しいUIを作るときのチェックリスト:
  - 余白が詰まりすぎていないか
  - 本文は `text-base` と `leading-7` を守っているか
  - アクセントカラーが1色に収まっているか
- 迷ったら参照する章:
  - 余白・文字サイズは「4」「5」「9」
- Bootstrap時代のクラスを持ち込まない
- PRレビューでは本ガイドに照らして確認する
