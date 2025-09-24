// esbuild用のapplication.js（CodeMirror完全修正版）
import { Application } from "@hotwired/stimulus"
import "@hotwired/turbo"
import * as ActiveStorage from "@rails/activestorage"

// ActiveStorageの確実な初期化
function ensureActiveStorage() {
    if (!window.ActiveStorage) {
        window.ActiveStorage = ActiveStorage;
        console.log('ActiveStorage: Global reference set');
    }

    if (!window.ActiveStorage.started) {
        ActiveStorage.start();
        window.ActiveStorage.started = true;
        console.log('ActiveStorage: Service started');
    }

    return window.ActiveStorage;
}

// 基本ライブラリを即座に初期化
const activeStorage = ensureActiveStorage();

// CodeMirrorの動的読み込み（修正版）
async function loadCodeMirror() {
    if (window.CodeMirror && window.CodeMirror.fromTextArea) {
        return window.CodeMirror;
    }

    try {
        console.log('Loading CodeMirror dynamically...');

        // 動的インポートでモジュール全体を取得
        const CodeMirrorModule = await import('codemirror');

        // モジュールから直接CodeMirrorオブジェクトを取得
        let CM = CodeMirrorModule.default || CodeMirrorModule || window.CodeMirror;

        // CommonJS形式の場合の対処
        if (!CM && typeof CodeMirrorModule === 'object') {
            // モジュールオブジェクトのプロパティを確認
            CM = Object.values(CodeMirrorModule).find(val =>
                val && typeof val === 'function' && val.fromTextArea
            ) || CodeMirrorModule;
        }

        if (!CM || typeof CM.fromTextArea !== 'function') {
            throw new Error('CodeMirror.fromTextArea not found');
        }

        // モードとアドオンを動的に読み込み
        await Promise.all([
            import('codemirror/mode/markdown/markdown'),
            import('codemirror/mode/javascript/javascript'),
            import('codemirror/mode/xml/xml'),
            import('codemirror/mode/css/css'),
            import('codemirror/addon/fold/foldcode'),
            import('codemirror/addon/fold/foldgutter'),
            import('codemirror/addon/fold/brace-fold'),
            import('codemirror/addon/fold/markdown-fold')
        ]);

        window.CodeMirror = CM;
        console.log('CodeMirror loaded successfully:', !!CM.fromTextArea);
        return CM;

    } catch (error) {
        console.error('CodeMirror loading failed:', error);
        return null;
    }
}

// VideoJS動的読み込み
async function loadVideoJS() {
    if (window.videojs) return window.videojs;

    try {
        const videojs = await import('video.js');
        window.videojs = videojs.default;
        return videojs.default;
    } catch (error) {
        console.error('Video.js loading failed:', error);
        return null;
    }
}

// グローバル読み込み関数をエクスポート
window.loadCodeMirror = loadCodeMirror;
window.loadVideoJS = loadVideoJS;

// CodeMirrorをプリロード（関数定義後に実行）
console.log('Pre-loading CodeMirror...')
loadCodeMirror().then(() => {
    console.log('CodeMirror pre-loaded successfully')
}).catch(error => {
    console.warn('CodeMirror pre-loading failed:', error)
})

// Stimulusアプリケーションを開始
const application = Application.start()
window.Stimulus = application

// Controllers の登録
import FlatpickrController from "./controllers/flatpickr_controller"
import CodeEditorController from "./controllers/code_editor_controller"
import VideoPlayerController from "./controllers/video_player_controller"

application.register("flatpickr", FlatpickrController)
application.register("code-editor", CodeEditorController)
application.register("video-player", VideoPlayerController)

console.log('Application loaded with esbuild (CodeMirror dynamic)')

// ActiveStorage初期化イベントを適切なタイミングで発火
function fireActiveStorageInitialized() {
    const event = new CustomEvent('activestorage:initialized', {
        detail: { ActiveStorage: window.ActiveStorage }
    });
    document.dispatchEvent(event);
    console.log('ActiveStorage: Initialization event dispatched');
}

function initializeActiveStorageEvents() {
    setTimeout(() => {
        fireActiveStorageInitialized();
    }, 100);
}

// 複数のイベントで初期化を試行
if (document.readyState === 'loading') {
    document.addEventListener('DOMContentLoaded', initializeActiveStorageEvents);
} else {
    initializeActiveStorageEvents();
}
document.addEventListener('turbo:load', initializeActiveStorageEvents);
document.addEventListener('turbo:render', initializeActiveStorageEvents);

window.addEventListener('load', () => {
    setTimeout(fireActiveStorageInitialized, 200);
});

// ActiveStorage確認用のグローバル関数
window.checkActiveStorageStatus = function() {
    const status = {
        available: typeof window.ActiveStorage !== 'undefined',
        directUpload: typeof window.ActiveStorage?.DirectUpload === 'function',
        started: window.ActiveStorage?.started || false
    };
    console.log('ActiveStorage Status:', status);
    return status;
};

console.log('ActiveStorage initialized and ready')