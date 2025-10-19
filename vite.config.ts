// vite.config.ts
import { defineConfig } from 'vite'
import RubyPlugin from 'vite-plugin-ruby'

export default defineConfig({
    plugins: [RubyPlugin()],
    server: {
        host: 'localhost',
        port: 3036,
        strictPort: true,
        hmr: { host: '127.0.0.1', port: 3036 }
        // hmr は host/port のみでOK。path は未指定（推奨）
        // hmr: { host: 'localhost', port: 3036 }

        // もし明示したいなら、末尾スラッシュ無しで '/vite' に固定（←これ重要）
        // hmr: { host: 'localhost', port: 3036, path: '/vite' },
    },
})