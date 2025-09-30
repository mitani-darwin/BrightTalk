import { Controller } from "@hotwired/stimulus"
import videojs from 'video.js'

export default class extends Controller {
    static targets = ["video"]

    connect() {
        console.log("VideoPlayer controller connected")
        console.log("hasVideoTarget:", this.hasVideoTarget)
        console.log("videoTargets length:", this.videoTargets ? this.videoTargets.length : 'undefined')
        console.log("All targets:", this.element.querySelectorAll('[data-video-player-target="video"]'))

        // DOM が完全に準備できてから初期化
        if (document.readyState === 'loading') {
            document.addEventListener('DOMContentLoaded', () => {
                console.log("DOMContentLoaded - calling initializePlayer")
                this.initializePlayer()
            })
        } else {
            console.log("Document already ready - calling initializePlayer")
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
        console.log('initializePlayer called')
        console.log('hasVideoTarget:', this.hasVideoTarget)
        console.log('videoTargets:', this.videoTargets)

        // より確実なvideo要素の取得
        const videoElement = this.element.querySelector('[data-video-player-target="video"]')
        console.log('Video element found:', videoElement)

        if (!videoElement) {
            console.error('Video target element not found in controller element:', this.element)
            return
        }

        if (this.hasVideoTarget) {
            console.log('Using hasVideoTarget path')
            const videoTarget = this.videoTarget
            console.log('Video target:', videoTarget)
            console.log('Video target ID:', videoTarget.id)
            this.setupPlayer(videoTarget)
        } else {
            console.log('Using direct query selector path')
            console.log('Direct video element:', videoElement)
            console.log('Direct video element ID:', videoElement.id)
            this.setupPlayer(videoElement)
        }
    }

    setupPlayer(videoElement) {
        // Video.jsが利用可能かチェック
        if (typeof videojs === 'undefined') {
            console.error('Video.js library is not available')
            return
        }

        // 既にVideo.jsプレーヤーが初期化されているかチェック
        if (videoElement.classList.contains('vjs-tech')) {
            console.log('Video.js player already initialized for this element')
            return
        }

        // 既存のプレーヤーがある場合は破棄
        if (this.player) {
            console.log('Disposing existing player')
            this.player.dispose()
            this.player = null
        }

        // Video.js用のクラスを確実に追加
        if (!videoElement.classList.contains('video-js')) {
            videoElement.classList.add('video-js', 'vjs-default-skin')
        }

        // optionsオブジェクトを定義
        const options = {
            fluid: false,
            responsive: true,
            width: 'auto',  // 動画の実際の横幅
            height: 'auto', // 動画の実際の高さ
            controls: true,
            playbackRates: [0.5, 1, 1.25, 1.5, 2],
            language: 'ja'
        }

        try {
            console.log('Attempting to initialize Video.js player with element:', videoElement.id)
            // DOM要素を直接渡してより確実に初期化
            this.player = videojs(videoElement, options, () => {
                console.log('Video.js player is ready')
                
                // 動画の実際のサイズを取得
                this.player.ready(() => {
                    const videoWidth = this.player.videoWidth()
                    const videoHeight = this.player.videoHeight()
                    
                    if (videoWidth && videoHeight) {
                        this.player.width(videoWidth)
                        this.player.height(videoHeight)
                        console.log('Video size set to:', videoWidth, 'x', videoHeight)
                    }
                })
            })
            console.log('Player created successfully:', this.player)
        } catch (error) {
            console.error('Failed to initialize Video.js player:', error)
        }
    }
}