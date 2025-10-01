import { Controller } from "@hotwired/stimulus"
import videojs from 'video.js'

export default class extends Controller {
    static targets = ["video"]

    connect() {
        console.log("VideoPlayer controller connected")

        if (document.readyState === 'loading') {
            document.addEventListener('DOMContentLoaded', () => {
                this.initializePlayer()
            })
        } else {
            this.initializePlayer()
        }
    }

    disconnect() {
        if (this.player) {
            this.player.dispose()
            this.player = null
        }
    }

    initializePlayer() {
        const videoElement = this.element.querySelector('[data-video-player-target="video"]')

        if (!videoElement) {
            console.error('Video target element not found')
            return
        }

        this.setupPlayer(videoElement)
    }

    setupPlayer(videoElement) {
        if (typeof videojs === 'undefined') {
            console.error('Video.js library is not available')
            return
        }

        // 既にVideo.jsプレーヤーが初期化されているかチェック
        if (videoElement.classList.contains('vjs-tech')) {
            console.log('Video.js player already initialized')
            return
        }

        // 既存のプレーヤーがある場合は破棄
        if (this.player) {
            this.player.dispose()
            this.player = null
        }

        // Video.js用のクラスを追加
        if (!videoElement.classList.contains('video-js')) {
            videoElement.classList.add('video-js', 'vjs-default-skin')
        }

        // ★修正: レスポンシブ対応のオプション設定
        const options = {
            fluid: true,           // コンテナに合わせてサイズ調整
            responsive: true,      // レスポンシブ対応を有効化
            fill: false,          // アスペクト比を維持
            aspectRatio: 'auto',  // 動画の元のアスペクト比を使用
            controls: true,
            playbackRates: [0.5, 1, 1.25, 1.5, 2],
            language: 'ja'
        }

        try {
            this.player = videojs(videoElement, options, () => {
                console.log('Video.js player is ready')

                // プレーヤー準備完了後にサイズ調整
                this.player.ready(() => {
                    this.adjustPlayerSize()

                    // ウィンドウリサイズ時にもサイズ調整
                    this.resizeHandler = this.debounce(() => {
                        this.adjustPlayerSize()
                    }, 250)

                    window.addEventListener('resize', this.resizeHandler)
                })
            })

        } catch (error) {
            console.error('Failed to initialize Video.js player:', error)
        }
    }

    // ★新規追加: プレーヤーサイズ調整メソッド
    adjustPlayerSize() {
        if (!this.player) return

        const containerElement = this.element
        const containerWidth = containerElement.offsetWidth

        // コンテナの最大幅を基準にサイズ調整
        if (containerWidth > 0) {
            // 16:9のアスペクト比を基本とするが、動画の実際のアスペクト比を優先
            let targetWidth = Math.min(containerWidth, 800) // 最大800px
            let targetHeight = targetWidth * (9 / 16) // デフォルト16:9

            // 動画の実際のアスペクト比を取得できる場合は使用
            const videoWidth = this.player.videoWidth()
            const videoHeight = this.player.videoHeight()

            if (videoWidth && videoHeight) {
                const aspectRatio = videoHeight / videoWidth
                targetHeight = targetWidth * aspectRatio
            }

            // 高さの制限（コンテナや画面サイズに応じて調整）
            const maxHeight = Math.min(window.innerHeight * 0.7, 600)
            if (targetHeight > maxHeight) {
                targetHeight = maxHeight
                targetWidth = targetHeight / (targetHeight / targetWidth)
            }

            console.log(`Adjusting video size to: ${targetWidth}x${targetHeight}`)

            // Video.jsプレーヤーのサイズを設定
            this.player.dimensions(targetWidth, targetHeight)
        }
    }

    // ★新規追加: デバウンス機能
    debounce(func, wait) {
        let timeout
        return (...args) => {
            clearTimeout(timeout)
            timeout = setTimeout(() => func.apply(this, args), wait)
        }
    }

    // ★修正: disconnect時にリサイズハンドラーも削除
    disconnect() {
        if (this.resizeHandler) {
            window.removeEventListener('resize', this.resizeHandler)
        }

        if (this.player) {
            this.player.dispose()
            this.player = null
        }
    }
}