// Configure your import map in config/importmap.rb. Read more: https://github.com/rails/importmap-rails
import "@hotwired/stimulus-loading"
import "controllers"

// Passkey module
import "passkey"

// CDNライブラリのimport文をすべて削除（ImportMapに依存）
// import "@hotwired/turbo"
// import "@hotwired/stimulus"
// import "spark-md5"
// import "codemirror"
// import "codemirror/mode/markdown/markdown"
// import "codemirror/mode/javascript/javascript"
// import "codemirror/mode/xml/xml"
// import "codemirror/mode/css/css"
// import "video.js"
// import "bootstrap"

// すべてImportMapに依存
// グローバルライブラリの初期化確認
document.addEventListener('DOMContentLoaded', function() {
    console.log('DOMContentLoaded - ActiveStorage check:', typeof window.ActiveStorage);
    console.log('Turbo loaded:', typeof window.Turbo !== 'undefined');
    console.log('Stimulus loaded:', typeof window.Stimulus !== 'undefined');
    console.log('CodeMirror loaded:', typeof window.CodeMirror !== 'undefined');
    console.log('SparkMD5 loaded:', typeof window.SparkMD5 !== 'undefined');
    console.log('videojs loaded:', typeof window.videojs !== 'undefined');

    // 遅延チェック
    setTimeout(() => {
        console.log('Delayed ActiveStorage check:', typeof window.ActiveStorage);
        if (typeof window.ActiveStorage !== 'undefined') {
            // CDNから読み込まれたActiveStorageを初期化
            if (!window.ActiveStorage.started) {
                window.ActiveStorage.start();
            }
            console.log('ActiveStorage methods:', Object.keys(window.ActiveStorage));
            console.log('ActiveStorage started:', window.ActiveStorage.started);
        } else {
            console.error('ActiveStorage failed to load from CDN');
        }
    }, 2000);
});