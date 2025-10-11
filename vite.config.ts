// vite.config.ts
import { defineConfig } from 'vite'
import RubyPlugin from 'vite-plugin-ruby'
import { resolve } from 'path'

export default defineConfig({
    plugins: [RubyPlugin()],
    base: '/vite/',
    server: { port: 3036, strictPort: true, hmr: { path: '/vite' } },
    build: {
        outDir: 'public/vite',
        assetsDir: 'assets',
        rollupOptions: {
            // ← ここを追加
            input: {
                application: resolve(__dirname, 'app/frontend/entrypoints/application.js'),
            },
            output: {
                manualChunks: {
                    // 必要なら分割
                    video: ['video.js'],
                    flatpickr: ['flatpickr'],
                    hotwired: ['@hotwired/stimulus', '@hotwired/turbo'],
                },
            },
        },
    },
})