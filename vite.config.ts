// vite.config.ts
import { defineConfig } from 'vite'
import RubyPlugin from 'vite-plugin-ruby'
import { resolve } from 'node:path'

export default defineConfig({
    plugins: [RubyPlugin()],
    server: {
        host: 'localhost',     // ← 追加（IPv4に固定）
        port: 3036,
        strictPort: true,
        hmr: {
            host: 'localhost',   // ← 追加（HMRも同一ホストに固定）
            port: 3036,
            protocol: 'ws',      // 開発は ws（もし https でアプリを開いているなら 'wss'）
        },
    },
    build: {
        outDir: 'public/vite',
        assetsDir: 'assets',
        rollupOptions: {
            input: {
                application: resolve(__dirname, 'app/frontend/entrypoints/application.js'),
                'entrypoints/new': resolve(__dirname, 'app/frontend/entrypoints/new.js'),
            },
        },
    },
})