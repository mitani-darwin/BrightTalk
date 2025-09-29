import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
    static targets = ["textarea"]

    connect() {
        console.log("CodeEditor controller connected")
        this.initializeCodeMirror()
    }

    async initializeCodeMirror() {
        // CodeMirrorが利用可能になるまで待機
        let retryCount = 0
        const maxRetries = 10

        while (retryCount < maxRetries) {
            if (window.CodeMirror && window.CodeMirror.fromTextArea) {
                break
            }

            console.log(`Waiting for CodeMirror... (attempt ${retryCount + 1})`)
            await new Promise(resolve => setTimeout(resolve, 100))
            retryCount++
        }

        if (!window.CodeMirror || !window.CodeMirror.fromTextArea) {
            console.error("CodeMirror is not available after waiting")
            return
        }

        const textarea = this.textareaTarget || this.element.querySelector('textarea')
        if (!textarea) {
            console.error("Textarea not found in CodeEditor controller")
            console.log("Available targets:", this.targets)
            console.log("Element:", this.element)
            return
        }

        console.log("Found textarea:", textarea.id)

        try {
            // CodeMirrorエディタを初期化
            this.editor = window.CodeMirror.fromTextArea(textarea, {
                mode: 'markdown',
                theme: 'default',
                lineNumbers: true,
                lineWrapping: true,
                indentUnit: 2,
                tabSize: 2,
                extraKeys: {
                    "Ctrl-Space": "autocomplete"
                }
            })

            // 初期化完了イベントを発火
            this.dispatch('initialized', { detail: { editor: this.editor } })

            console.log('CodeMirror initialized successfully')

            // エディターが正常に作成されたかを確認
            if (this.editor && this.editor.getDoc) {
                console.log('CodeMirror editor is functional')
            } else {
                console.error('CodeMirror editor creation failed')
            }

        } catch (error) {
            console.error('CodeMirror initialization error:', error)
        }
    }

    insertText(text) {
        if (this.editor && this.editor.getDoc) {
            const cursor = this.editor.getCursor()
            this.editor.replaceRange(text, cursor)
            this.editor.focus()
        } else {
            console.warn('CodeMirror editor not available for text insertion')
        }
    }

    disconnect() {
        if (this.editor) {
            try {
                this.editor.toTextArea()
                this.editor = null
                console.log('CodeEditor disconnected')
            } catch (error) {
                console.error('Error during CodeEditor disconnect:', error)
            }
        }
    }
}