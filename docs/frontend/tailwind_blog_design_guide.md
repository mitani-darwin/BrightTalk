# ブログ用 Tailwind デザインガイド（余白・文字サイズ）

## 1. デザイン思想（Why）
- **余白と文字サイズを最優先**: 長文の読みやすさは、情報量より「呼吸できる間隔」で決まる
- **可読性の原則**: 行間を十分に取り、1行の文字数を抑えると疲れにくい
- **Bootstrapとの違い**: デフォルトの汎用UIではなく、読み物に最適化したタイポグラフィと間を作る

## 2. ベースレイアウト基準
- **最大幅（max-width）**
  - 記事本文: `max-w-prose` または `max-w-[720px]`
  - 一覧ページ: `max-w-screen-xl`
- **中央寄せの基本**
  - 全ページ共通で `mx-auto` を基本にする
- **左右余白（padding）**
  - モバイル: `px-4`
  - タブレット: `sm:px-6`
  - デスクトップ: `lg:px-10`

## 3. 文字サイズ・行間ルール（最重要）
- **body 基本文字サイズ**
  - 基本: `text-base`（モバイルでも下げない）
  - 長文記事: `text-base` + `leading-7`
- **行間の基準**
  - 本文: `leading-7`（標準）
  - 抜粋: `leading-relaxed`
- **見出し（h1〜h4）**
  - h1: `text-3xl md:text-4xl leading-tight font-semibold`
  - h2: `text-2xl md:text-3xl leading-snug font-semibold`
  - h3: `text-xl md:text-2xl leading-snug font-semibold`
  - h4: `text-lg md:text-xl leading-snug font-semibold`
- **モバイルとPCの差**
  - 文字サイズは小さくしすぎない
  - 余白は段階的に増やす（`sm` / `lg` で調整）

## 4. 記事本文（prose）の設計指針
- **Tailwind Typography（prose）を使う場合**
  - 推奨: `prose prose-slate max-w-none`
  - 余白: `prose-p:leading-7 prose-headings:scroll-mt-24`
- **prose を使わない場合**
  - 本文: `text-base leading-7 text-slate-700`
  - 見出し: `mt-10 mb-4` を基本
- **段落・リスト・引用・コード**
  - 段落: `mb-5`
  - リスト: `my-4 pl-6`
  - 引用: `my-6 border-l-4 border-slate-200 pl-4 text-slate-600`
  - コードブロック: `my-6 rounded-lg bg-slate-950/90 p-4 text-slate-100`
- **行の長さ（文字数目安）**
  - 1行あたり 35〜40文字程度を目安

## 5. 記事一覧・カードUIの余白ルール
- **カード内余白**: `p-5`（密度を下げる）
- **カード間余白**: `gap-6`（一覧の呼吸）
- **タイトル・メタ・抜粋**
  - タイトル→抜粋: `space-y-2`
  - メタ情報→本文: `gap-4`
- **hoverの変化は控えめ**
  - `hover:shadow-md` / `hover:-translate-y-0.5` 程度
  - 強すぎる動きは読みの集中を乱す

## 6. 色とコントラスト（簡潔）
- **本文色**: `text-slate-700` を基本
- **見出し色**: `text-slate-900`
- **背景色**: `bg-white` と `bg-slate-50` のみで構成
- **アクセント**: `brand` 1色のみで統一（リンクやボタン）

## 7. レスポンシブ設計の考え方
- **モバイルファースト**: まず `px-4 text-base` を基準にする
- **変えるもの**: カラム数、カードの並び、余白
- **変えないもの**: 基本文字サイズと本文行間

## 8. Tailwindクラス早見表（実務向け）
- 記事本文: `text-base leading-7 text-slate-700`
- 記事タイトル: `text-2xl font-semibold leading-tight`
- 抜粋: `text-sm text-slate-600 leading-relaxed`
- メタ情報: `text-xs text-slate-500`
- カード余白: `p-5`
- カード間隔: `gap-6`

### NGパターン
- `text-xs` を本文に使う（詰まりすぎ）
- `leading-tight` を本文に使う（読み疲れ）
- `p-2` のように余白を削る（管理画面っぽくなる）

## 9. 実装例（Railsビュー）
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

## 10. デザインガイドの運用ルール
- **迷ったら**: このガイドの「早見表」と「実装例」を優先
- **新UI作成時のチェック**
  - 余白が十分か（詰まっていないか）
  - 本文は `text-base` と `leading-7` を維持しているか
  - アクセントカラーが1色に収まっているか
- **注意**: Bootstrap時代のクラス（`row`, `col`, `btn`, `card`）を持ち込まない
