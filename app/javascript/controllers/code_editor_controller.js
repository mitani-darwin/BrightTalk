import {Controller} from "@hotwired/stimulus"

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
            console.log('Starting CodeMirror initialization...');

            // CodeMirrorが読み込まれるまで待機（タイムアウト処理付き）
            await this.waitForCodeMirror()

            // グローバルCodeMirrorオブジェクトを使用
            const CM = window.CodeMirror

            if (!CM || typeof CM.fromTextArea !== 'function') {
                throw new Error('CodeMirror.fromTextArea is not available');
            }

            console.log('Initializing CodeMirror editor...');

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
                    "Tab": function (cm) {
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

            // 初期化完了イベントを発火
            this.element.dispatchEvent(new CustomEvent('code-editor:initialized'));

        } catch (error) {
            console.error('CodeMirror initialization failed:', error)
            this.initializeFallbackMode()
        }
    }

    async waitForCodeMirror() {
        // 動的読み込みを確実に実行
        if (!window.CodeMirror || !window.CodeMirror.fromTextArea) {
            try {
                console.log('Attempting to load CodeMirror...');
                const result = await window.loadCodeMirror();
                if (result && result.fromTextArea) {
                    console.log('CodeMirror loaded successfully via dynamic import');
                    return Promise.resolve(true);
                }
            } catch (error) {
                console.error('Failed to load CodeMirror dynamically:', error);
            }
        }

        // 既に利用可能な場合は即座に返す
        if (window.CodeMirror && typeof window.CodeMirror.fromTextArea === 'function') {
            console.log('CodeMirror already available');
            return Promise.resolve(true);
        }

        // ポーリングによる待機処理
        let attempts = 0
        const maxAttempts = 50  // 5秒間待機（100ms × 50回）

        return new Promise((resolve, reject) => {
            const checkInterval = setInterval(() => {
                attempts++

                if (window.CodeMirror && typeof window.CodeMirror.fromTextArea === 'function') {
                    clearInterval(checkInterval)
                    console.log('CodeMirror confirmed available after', attempts, 'attempts');
                    resolve(true)
                } else if (attempts >= maxAttempts) {
                    clearInterval(checkInterval)
                    console.error('CodeMirror not available after', attempts, 'attempts');
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
            textarea.dispatchEvent(new Event('change', {bubbles: true}))
            textarea.dispatchEvent(new Event('input', {bubbles: true}))
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

    // 現在の値を取得するメソッドを追加
    getValue() {
        if (this.editor) {
            return this.editor.getValue()
        } else {
            return this.textareaTarget.value
        }
    }

    // フォーカス状態を確認するメソッドを追加
    hasFocus() {
        if (this.editor) {
            return this.editor.hasFocus()
        } else {
            return document.activeElement === this.textareaTarget
        }
    }

    // エディタを安全にリフレッシュするメソッドを追加
    refreshEditor() {
        if (this.editor) {
            setTimeout(() => {
                this.editor.refresh()
                this.editor.focus()
            }, 100)
        }
    }
}