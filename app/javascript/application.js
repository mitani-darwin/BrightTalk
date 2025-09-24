// esbuild用のapplication.js
import { Application } from "@hotwired/stimulus"
import "@hotwired/turbo"

// CodeMirrorをインポートしてグローバルに設定
import CodeMirror from "codemirror"
import "codemirror/mode/markdown/markdown"
import "codemirror/mode/javascript/javascript"
import "codemirror/mode/xml/xml"
import "codemirror/mode/css/css"
import "codemirror/addon/fold/foldcode"
import "codemirror/addon/fold/foldgutter"
import "codemirror/addon/fold/brace-fold"
import "codemirror/addon/fold/markdown-fold"

// Video.jsをインポートしてグローバルに設定
import videojs from "video.js"
window.videojs = videojs

// CodeMirrorをグローバルに設定
window.CodeMirror = CodeMirror

// Stimulusアプリケーションを開始
const application = Application.start()

// Stimulusをグローバルに利用可能にする
window.Stimulus = application

// Controllers の登録
import FlatpickrController from "./controllers/flatpickr_controller"
import CodeEditorController from "./controllers/code_editor_controller"
import VideoPlayerController from "./controllers/video_player_controller"

application.register("flatpickr", FlatpickrController)
application.register("code-editor", CodeEditorController)
application.register("video-player", VideoPlayerController)

console.log('Application loaded with esbuild, CodeMirror, and Video.js')