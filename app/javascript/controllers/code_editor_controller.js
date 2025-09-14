import { Controller } from "@hotwired/stimulus"
// CodeMirrorはCDNから読み込み、グローバル変数として使用

export default class extends Controller {
  static targets = ["textarea"]

  connect() {
    // CodeMirrorが利用可能になるまで待つ（プリコンパイル環境対応）
    this.waitForCodeMirror()
  }

  disconnect() {
    if (this.editor) {
      this.editor.toTextArea()
    }
  }

  async waitForCodeMirror() {
    // CodeMirrorがグローバルオブジェクトとして利用可能になるまで待つ
    let attempts = 0
    const maxAttempts = 50
    
    const checkCodeMirror = () => {
      return new Promise((resolve) => {
        const check = () => {
          attempts++
          if (window.CodeMirror && typeof window.CodeMirror.fromTextArea === 'function') {
            resolve(true)
          } else if (attempts < maxAttempts) {
            setTimeout(check, 100)
          } else {
            resolve(false)
          }
        }
        check()
      })
    }
    
    const isAvailable = await checkCodeMirror()
    if (isAvailable) {
      this.initializeEditor()
    } else {
      console.warn('CodeMirror failed to load, falling back to plain textarea')
    }
  }

  initializeEditor() {
    const textarea = this.textareaTarget
    
    // グローバルのCodeMirrorオブジェクトを使用
    const CM = window.CodeMirror
    
    if (!CM || typeof CM.fromTextArea !== 'function') {
      console.error('CodeMirror is not available or fromTextArea method is missing')
      return
    }
    
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

    // Sync editor content with textarea for form submission and validation
    this.editor.on("change", () => {
      textarea.value = this.editor.getValue()
      // Clear custom validity when content changes
      textarea.setCustomValidity('')
      // Trigger change and input events for validation
      textarea.dispatchEvent(new Event('change', { bubbles: true }))
      textarea.dispatchEvent(new Event('input', { bubbles: true }))
    })

    // Handle form validation by making CodeMirror focusable
    const form = textarea.closest('form')
    if (form) {
      form.addEventListener('submit', (e) => {
        // Sync content before validation
        textarea.value = this.editor.getValue()
        
        // If textarea is invalid, focus the CodeMirror editor
        if (!textarea.checkValidity()) {
          e.preventDefault()
          this.editor.focus()
          // Show custom validation message
          textarea.setCustomValidity('内容を入力してください')
          textarea.reportValidity()
          return false
        }
      })
    }

    // Handle HTML5 constraint validation API
    textarea.addEventListener('invalid', (e) => {
      e.preventDefault()
      this.editor.focus()
    })

    // Set initial height
    this.editor.setSize(null, "400px")
    
    // Focus the editor when clicked and clear validation state
    this.editor.on("focus", () => {
      this.editor.refresh()
      textarea.setCustomValidity('')
    })
    
    // Initialize with current content
    if (textarea.value) {
      this.editor.setValue(textarea.value)
    }
  }

  // Method to insert text at cursor position (for image/video insertion)
  insertText(text) {
    if (this.editor) {
      const doc = this.editor.getDoc()
      const cursor = doc.getCursor()
      doc.replaceRange(text, cursor)
      this.editor.focus()
    }
  }

  // Method to get current cursor position for external usage
  getCursorPosition() {
    if (this.editor) {
      return this.editor.getDoc().getCursor()
    }
    return null
  }
}