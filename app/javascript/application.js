
// Configure your import map in config/importmap.rb. Read more: https://github.com/rails/importmap-rails
import "@rails/activestorage"
import "@hotwired/turbo-rails"
import "controllers"

// CodeMirrorをグローバルに読み込み
import "codemirror"
import "codemirror/mode/markdown/markdown"

// ActiveStorage 初期化の確認
document.addEventListener('DOMContentLoaded', function() {
    console.log('DOMContentLoaded - ActiveStorage check:', typeof window.ActiveStorage);

    // 遅延チェック
    setTimeout(() => {
        console.log('Delayed ActiveStorage check:', typeof window.ActiveStorage);
        if (typeof window.ActiveStorage !== 'undefined') {
            console.log('ActiveStorage methods:', Object.keys(window.ActiveStorage));
        } else {
            console.error('ActiveStorage failed to load');
        }
    }, 2000);
});