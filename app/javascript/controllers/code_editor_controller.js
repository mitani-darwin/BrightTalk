import { Controller } from "@hotwired/stimulus"
import CodeMirror from "codemirror"
import "codemirror/mode/markdown/markdown"
import "codemirror/mode/javascript/javascript"
import "codemirror/mode/xml/xml"
import "codemirror/mode/css/css"

export default class extends Controller {
  static targets = ["textarea"]

  connect() {
    this.initializeEditor()
  }

  disconnect() {
    if (this.editor) {
      this.editor.toTextArea()
    }
  }

  initializeEditor() {
    const textarea = this.textareaTarget
    
    this.editor = CodeMirror.fromTextArea(textarea, {
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

    // Sync editor content with textarea for form submission
    this.editor.on("change", () => {
      textarea.value = this.editor.getValue()
      // Trigger change event for any other listeners
      textarea.dispatchEvent(new Event('change', { bubbles: true }))
    })

    // Set initial height
    this.editor.setSize(null, "400px")
    
    // Focus the editor when clicked
    this.editor.on("focus", () => {
      this.editor.refresh()
    })
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