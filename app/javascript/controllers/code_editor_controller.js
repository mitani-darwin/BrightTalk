import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["textarea"]

  connect() {
    this.initializeCodeMirror()
  }

  disconnect() {
    if (this.editor) {
      this.editor.toTextArea()
    }
  }

  async initializeCodeMirror() {
    const textarea = this.textareaTarget
    
    try {
      // CodeMirrorが読み込まれるまで待機
      await this.waitForCodeMirror()
      
      // グローバルCodeMirrorオブジェクトを使用
      const CM = window.CodeMirror
      
      // CodeMirrorエディターを初期化
      this.editor = CM.fromTextArea(textarea, {
        mode: "markdown",
        theme: "default",
        lineNumbers: true,
        lineWrapping: true,
        indentUnit: 2,
        tabSize: 2,
        autoCloseBrackets: true,
        matchBrackets: true,
        showCursorWhenSelecting: true,
        styleActiveLine: true,
        foldGutter: true,
        gutters: ["CodeMirror-linenumbers", "CodeMirror-foldgutter"],
        extraKeys: {
          "Ctrl-Space": "autocomplete",
          "Tab": function(cm) {
            if (cm.somethingSelected()) {
              cm.indentSelection("add");
            } else {
              cm.replaceSelection("  ");
            }
          }
        }
      })

      // エディターの同期とバリデーション設定
      this.setupEditorSync()
      this.editor.setSize(null, "400px")
      
      if (textarea.value) {
        this.editor.setValue(textarea.value)
      }
      
      console.log('CodeMirror editor initialized successfully')
      
    } catch (error) {
      console.error('CodeMirror initialization failed:', error)
      this.initializeFallbackMode()
    }
  }

  async waitForCodeMirror() {
    let attempts = 0
    const maxAttempts = 100  // 10秒間待機

    return new Promise((resolve, reject) => {
      const checkInterval = setInterval(() => {
        attempts++
        
        if (window.CodeMirror && typeof window.CodeMirror.fromTextArea === 'function') {
          clearInterval(checkInterval)
          resolve(true)
        } else if (attempts >= maxAttempts) {
          clearInterval(checkInterval)
          reject(new Error('CodeMirror failed to load'))
        }
      }, 100)
    })
  }

  initializeFallbackMode() {
    const textarea = this.textareaTarget
    
    // フォールバック時の視覚的改善
    textarea.style.fontFamily = 'Monaco, "Lucida Console", monospace'
    textarea.style.fontSize = '14px'
    textarea.style.lineHeight = '1.5'
    textarea.style.padding = '10px'
    textarea.style.border = '1px solid #ddd'
    textarea.style.borderRadius = '4px'
    textarea.style.minHeight = '400px'
    textarea.style.resize = 'vertical'
    
    console.log('Fallback mode initialized')
  }

  setupEditorSync() {
    const textarea = this.textareaTarget
    
    this.editor.on("change", () => {
      textarea.value = this.editor.getValue()
      textarea.setCustomValidity('')
      textarea.dispatchEvent(new Event('change', { bubbles: true }))
      textarea.dispatchEvent(new Event('input', { bubbles: true }))
    })

    const form = textarea.closest('form')
    if (form) {
      form.addEventListener('submit', (e) => {
        textarea.value = this.editor.getValue()
        
        if (!textarea.checkValidity()) {
          e.preventDefault()
          this.editor.focus()
          textarea.setCustomValidity('内容を入力してください')
          textarea.reportValidity()
          return false
        }
      })
    }

    textarea.addEventListener('invalid', (e) => {
      e.preventDefault()
      this.editor.focus()
    })

    this.editor.on("focus", () => {
      this.editor.refresh()
      textarea.setCustomValidity('')
    })
  }

  // 画像・動画挿入用のメソッド
  insertText(text) {
    if (this.editor) {
      const doc = this.editor.getDoc()
      const cursor = doc.getCursor()
      doc.replaceRange(text, cursor)
      this.editor.focus()
    } else {
      // フォールバックモード用
      const textarea = this.textareaTarget
      const start = textarea.selectionStart
      const end = textarea.selectionEnd
      const before = textarea.value.substring(0, start)
      const after = textarea.value.substring(end)
      textarea.value = before + text + after
      textarea.selectionStart = textarea.selectionEnd = start + text.length
      textarea.focus()
    }
  }

  getCursorPosition() {
    if (this.editor) {
      return this.editor.getDoc().getCursor()
    }
    return null
  }
}