// esbuild用のapplication.js（CodeMirror完全修正版）
import { Application } from "@hotwired/stimulus"
import "@hotwired/turbo"
import * as ActiveStorage from "@rails/activestorage"
import videojs from 'video.js';
import 'video.js/dist/video-js/video-js.css';  // CSS追加
import { startPasskeyAuthentication, startPasskeyRegistration } from './passkey.js';
import flatpickr from 'flatpickr';
import 'flatpickr/dist/flatpickr.min.css';

window.videojs = videojs;

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
