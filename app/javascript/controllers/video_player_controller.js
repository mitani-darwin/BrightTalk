import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["video"]
  static values = { 
    src: String,
    type: String,
    poster: String
  }

  connect() {
    this.initializeVideoJS()
  }

  disconnect() {
    if (this.player) {
      this.player.dispose()
    }
  }

  async initializeVideoJS() {
    try {
      // Dynamically import Video.js
      const videojs = await import("video.js")
      const VideoJS = videojs.default

      // Video.js configuration options
      const options = {
        controls: true,
        responsive: true,
        fluid: true,
        preload: 'metadata',
        playbackRates: [0.5, 1, 1.25, 1.5, 2],
        techOrder: ['html5'],
        html5: {
          vhs: {
            overrideNative: true
          }
        }
      }

      // Initialize Video.js player
      this.player = VideoJS(this.videoTarget, options)

      // Set video source if provided
      if (this.hasSrcValue && this.hasTypeValue) {
        this.player.src({
          src: this.srcValue,
          type: this.typeValue
        })
      }

      // Set poster image if provided
      if (this.hasPosterValue) {
        this.player.poster(this.posterValue)
      }

      // Add event listeners
      this.setupEventListeners()

      console.log('Video.js player initialized successfully')
      
    } catch (error) {
      console.error('Failed to initialize Video.js:', error)
      // Fallback to native HTML5 video
      this.initializeFallback()
    }
  }

  setupEventListeners() {
    if (!this.player) return

    // Player ready event
    this.player.ready(() => {
      console.log('Video.js player is ready')
    })

    // Error handling
    this.player.on('error', (error) => {
      console.error('Video.js player error:', error)
      this.handleVideoError()
    })

    // Loading states
    this.player.on('loadstart', () => {
      console.log('Video loading started')
    })

    this.player.on('canplay', () => {
      console.log('Video can start playing')
    })
  }

  handleVideoError() {
    // Display user-friendly error message
    const errorContainer = document.createElement('div')
    errorContainer.className = 'alert alert-warning mt-2'
    errorContainer.innerHTML = `
      <i class="fas fa-exclamation-triangle me-2"></i>
      動画の読み込みに問題が発生しました。
      <a href="${this.srcValue}" target="_blank" class="alert-link">直接ダウンロード</a>してお試しください。
    `
    
    if (this.videoTarget.parentNode) {
      this.videoTarget.parentNode.insertBefore(errorContainer, this.videoTarget.nextSibling)
    }
  }

  initializeFallback() {
    // Enable native HTML5 video controls as fallback
    this.videoTarget.controls = true
    this.videoTarget.preload = 'metadata'
    
    if (this.hasSrcValue) {
      this.videoTarget.src = this.srcValue
    }
    
    if (this.hasPosterValue) {
      this.videoTarget.poster = this.posterValue
    }
    
    console.log('Fallback to native HTML5 video player')
  }

  // Public method to update video source
  updateSource(src, type) {
    if (this.player) {
      this.player.src({ src, type })
    } else {
      this.videoTarget.src = src
    }
  }

  // Public method to play video
  play() {
    if (this.player) {
      return this.player.play()
    } else {
      return this.videoTarget.play()
    }
  }

  // Public method to pause video
  pause() {
    if (this.player) {
      this.player.pause()
    } else {
      this.videoTarget.pause()
    }
  }
}