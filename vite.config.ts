// vite.config.ts
import { defineConfig } from 'vite'
import RubyPlugin from 'vite-plugin-ruby'

export default defineConfig({
    plugins: [RubyPlugin()],
    // 任意: dev ポートを固定したいならこれだけ残す
    server: { port: 3036, strictPort: true },
    // build 出力先をカスタムしたい場合のみ設定（なければ省略可）
    build: {
        outDir: 'public/vite',
        assetsDir: 'assets',
    },
})