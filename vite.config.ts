import { defineConfig } from 'vite'
import RubyPlugin from 'vite-plugin-ruby'

export default defineConfig({
    plugins: [RubyPlugin()],
    server: {
        host: 'localhost',
        port: 3036,
        strictPort: true,
        hmr: {
            host: 'localhost',
            port: 3036,
            path: '/vite/', // base に合わせる
        },
    },
})