// vite.config.ts
import { defineConfig } from 'vite'
import RubyPlugin from 'vite-plugin-ruby'
import { resolve } from 'node:path'

export default defineConfig({
    plugins: [RubyPlugin()],
    server: { port: 3036, strictPort: true },
    build: {
        outDir: 'public/vite',
        assetsDir: 'assets',
        rollupOptions: {
            input: {
                // レイアウトの `vite_javascript_tag 'application'` に対応
                application: resolve(__dirname, 'app/frontend/entrypoints/application.js'),
                // パスキー画面の `vite_javascript_tag 'entrypoints/new'` に対応
                'entrypoints/new': resolve(__dirname, 'app/frontend/entrypoints/new.js'),
            },
        },
    },
})