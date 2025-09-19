// Configure your import map in config/importmap.rb. Read more: https://github.com/rails/importmap-rails
import * as ActiveStorage from "@rails/activestorage"
import "@hotwired/stimulus-loading"
import "controllers"

// Passkey module
import "passkey"

// CDN配信によるJavaScriptライブラリを動的にインポートしてグローバルに設定
async function loadLibraries() {
    try {
        // Turbo
        const { Turbo } = await import("@hotwired/turbo")
        window.Turbo = Turbo

        // Stimulus
        const { Application } = await import("@hotwired/stimulus")
        if (!window.Stimulus) {
            window.Stimulus = { Application }
        }

        // SparkMD5
        const SparkMD5Module = await import("spark-md5")
        window.SparkMD5 = SparkMD5Module.default || SparkMD5Module

        // CodeMirror とモード
        const CodeMirrorModule = await import("codemirror")
        window.CodeMirror = CodeMirrorModule.default || CodeMirrorModule
        
        // CodeMirror モードを順次読み込み
        await import("codemirror/mode/markdown/markdown")
        await import("codemirror/mode/javascript/javascript")
        await import("codemirror/mode/xml/xml")
        await import("codemirror/mode/css/css")

        // Video.js
        const videojsModule = await import("video.js")
        window.videojs = videojsModule.default || videojsModule

        // Bootstrap
        const bootstrapModule = await import("bootstrap")
        window.bootstrap = bootstrapModule.default || bootstrapModule

        console.log('All CDN libraries loaded successfully')
        
        // ライブラリの読み込み状況をログ出力
        console.log('Library status:')
        console.log('- Turbo:', typeof window.Turbo)
        console.log('- Stimulus:', typeof window.Stimulus)
        console.log('- ActiveStorage:', typeof window.ActiveStorage)
        console.log('- SparkMD5:', typeof window.SparkMD5)
        console.log('- CodeMirror:', typeof window.CodeMirror)
        console.log('- videojs:', typeof window.videojs)
        console.log('- bootstrap:', typeof window.bootstrap)

    } catch (error) {
        console.error('Failed to load some libraries:', error)
    }
}

// ActiveStorage をグローバルスコープに設定
window.ActiveStorage = ActiveStorage

// ActiveStorage を開始
ActiveStorage.start()

// ライブラリの動的読み込みを実行
loadLibraries()

// DOMContentLoaded時の追加チェック
document.addEventListener('DOMContentLoaded', function() {
    console.log('DOMContentLoaded - Library check completed')
})
