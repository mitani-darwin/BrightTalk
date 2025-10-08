// esbuild用のapplication.js（CodeMirror完全修正版）
import { Application } from "@hotwired/stimulus"
import "@hotwired/turbo"
import * as ActiveStorage from "@rails/activestorage"
import videojs from 'video.js';
import 'video.js/dist/video-js.css';  // CSS追加
import { startPasskeyAuthentication, startPasskeyRegistration } from './passkey.js';
import { EditorView, basicSetup } from 'codemirror';
import { EditorState } from '@codemirror/state';
import { markdown } from '@codemirror/lang-markdown';
import { oneDark } from '@codemirror/theme-one-dark';
import { foldGutter, codeFolding } from '@codemirror/language';
import flatpickr from 'flatpickr';
import 'flatpickr/dist/flatpickr.min.css';

window.videojs = videojs;
// CodeMirror 6 objects for global access
window.CodeMirror = {
    EditorView,
    EditorState,
    basicSetup,
    markdown,
    oneDark,
    foldGutter,
    codeFolding
};

window.flatpickr = flatpickr;

window.startPasskeyAuthentication = startPasskeyAuthentication;
window.startPasskeyRegistration = startPasskeyRegistration;

console.log('Passkey functions loaded globally:', {
    auth: !!window.startPasskeyAuthentication,
    reg: !!window.startPasskeyRegistration
});

// ActiveStorageの簡単な初期化
if (!window.ActiveStorage) {
    window.ActiveStorage = ActiveStorage;
    ActiveStorage.start();
    console.log('ActiveStorage initialized');
}

// CodeMirror 6の確実な読み込み
async function loadCodeMirror() {
    // 既に window.CodeMirror が正しく設定されている場合はそれを返す
    if (window.CodeMirror && window.CodeMirror.EditorView) {
        console.log('CodeMirror 6 already available');
        return window.CodeMirror;
    }

    try {
        console.log('Ensuring CodeMirror 6 is available...');

        // CodeMirror 6オブジェクトが設定済みかチェック
        const CM = window.CodeMirror;
        
        if (!CM || !CM.EditorView || !CM.EditorState) {
            throw new Error('CodeMirror 6 modules not available');
        }

        console.log('CodeMirror 6 confirmed available');
        return CM;

    } catch (error) {
        console.error('CodeMirror 6 setup failed:', error);
        return null;
    }
}

// グローバル読み込み関数をエクスポート
window.loadCodeMirror = loadCodeMirror;

// Video.jsの読み込み関数（修正版 - 動的インポートを削除）
async function loadVideoJS() {
    // 既に静的にインポートされているVideo.jsを返す
    if (window.videojs) {
        console.log('Video.js already available:', !!window.videojs);
        return window.videojs;
    }

    console.warn('Video.js not found on window object');
    return null;
}

window.loadVideoJS = loadVideoJS;

// CodeMirrorをプリロード（関数定義後に実行）
console.log('Pre-loading CodeMirror...')
loadCodeMirror().then(() => {
    console.log('CodeMirror pre-loaded successfully')
}).catch(error => {
    console.warn('CodeMirror pre-loading failed:', error)
})

// Video.jsをプリロード（修正版）
console.log('Pre-loading Video.js...')
loadVideoJS().then(() => {
    console.log('Video.js pre-loaded successfully, window.videojs available:', !!window.videojs)
}).catch(error => {
    console.warn('Video.js pre-loading failed:', error)
})

// Stimulusアプリケーションを開始
const application = Application.start()
window.Stimulus = application

// Controllers の登録
import CodeEditorController from "./controllers/code_editor_controller"
import VideoPlayerController from "./controllers/video_player_controller"
import FlatpickrController from "./controllers/flatpickr_controller"

application.register("code-editor", CodeEditorController)
application.register("video-player", VideoPlayerController)
application.register("flatpickr", FlatpickrController)

console.log('Application loaded with esbuild (CodeMirror dynamic)')

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

// CSRF token handling for Turbo
document.addEventListener('turbo:before-fetch-request', (event) => {
    const token = document.querySelector('meta[name="csrf-token"]').getAttribute('content');
    if (token) {
        event.detail.fetchOptions.headers['X-CSRF-Token'] = token;
    }
});

console.log('ActiveStorage initialized and ready')