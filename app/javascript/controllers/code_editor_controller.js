import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
    static targets = ["textarea"]

    connect() {
        console.log("CodeEditor controller connected")
        // 既に初期化済みかチェック
        if (this.element.classList.contains('codemirror-initialized')) {
            console.log("CodeEditorは既に設定済みです")
            return
        }
        this.initializeCodeMirror();
        
        // 動的サイズ調整の初期化を追加
        this.initializeDynamicSizing();
        
        // カスタムイベントリスナーを追加
        this.element.addEventListener('code-editor:insert-text', this.handleInsertText.bind(this))
    }

    async initializeCodeMirror() {
        // 初期化フラグを設定
        this.element.classList.add('codemirror-initializing')
        
        // CodeMirrorの確実な読み込みを試行
        try {
            // loadCodeMirror関数を使用してCodeMirrorを取得
            const CodeMirror = await window.loadCodeMirror?.() || window.CodeMirror;
            
            if (!CodeMirror || typeof CodeMirror.fromTextArea !== 'function') {
                // 追加の待機ロジック
                console.log("CodeMirror not immediately available, waiting...")
                let retryCount = 0
                const maxRetries = 15
                
                while (retryCount < maxRetries) {
                    if (window.CodeMirror && typeof window.CodeMirror.fromTextArea === 'function') {
                        break
                    }
                    console.log(`Waiting for CodeMirror... (attempt ${retryCount + 1}/${maxRetries})`)
                    await new Promise(resolve => setTimeout(resolve, 200))
                    retryCount++
                }
            }
            
            if (!window.CodeMirror || typeof window.CodeMirror.fromTextArea !== 'function') {
                throw new Error("CodeMirror is not available after waiting")
            }
            
        } catch (error) {
            console.error("Failed to initialize CodeMirror:", error)
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
                },
                resize: true,
            })

            // 初期化完了イベントを発火
            this.dispatch('initialized', { detail: { editor: this.editor } })

            console.log('CodeMirror initialized successfully')

            // エディターが正常に作成されたかを確認
            if (this.editor && this.editor.getDoc) {
                console.log('CodeMirror editor is functional')

                this.element.classList.remove('codemirror-initializing')
                this.element.classList.add('codemirror-initialized')
            } else {
                console.error('CodeMirror editor creation failed')
            }

            // 初期化直後に強制サイズ設定
            setTimeout(() => {
                this.adjustEditorSize();
            }, 100);

            // さらに確実にするため、500ms後にも実行
            setTimeout(() => {
                this.adjustEditorSize();
            }, 500);

        } catch (error) {
            console.error('CodeMirror initialization error:', error)
        }
    }

    initializeDynamicSizing() {
        console.log('動的サイズ調整を初期化中...');
        
        // 初期サイズ調整
        this.adjustEditorSize();
        
        // リサイズイベントリスナー
        this.resizeHandler = this.debounce(() => this.adjustEditorSize(), 250);
        window.addEventListener('resize', this.resizeHandler);
        
        // デバイス向き変更イベント
        this.orientationHandler = () => setTimeout(() => this.adjustEditorSize(), 500);
        window.addEventListener('orientationchange', this.orientationHandler);
        
        console.log('動的サイズ調整が有効になりました');
    }

    adjustEditorSize() {
        if (!this.editor) return;

        // より大きなサイズ設定
        const minHeight = 600; // 400px → 600px
        const maxHeight = 800; // 600px → 800px
        const targetHeight = Math.min(maxHeight, Math.max(minHeight, window.innerHeight * 0.6));

        // CodeMirrorの各要素に確実に大きなサイズを適用
        const wrapper = this.editor.getWrapperElement();
        const scrollElement = this.editor.getScrollerElement();

        if (wrapper) {
            // wrapperに直接大きなサイズ設定
            wrapper.style.height = `${targetHeight}px`;
            wrapper.style.minHeight = `${minHeight}px`;
            wrapper.style.maxHeight = `${maxHeight}px`;
            wrapper.style.overflow = 'hidden';

            // CSSクラスも追加
            wrapper.classList.add('codemirror-sized');
        }

        if (scrollElement) {
            // scrollElementにも同じ大きなサイズ設定
            scrollElement.style.height = `${targetHeight}px`;
            scrollElement.style.minHeight = `${minHeight}px`;
            scrollElement.style.maxHeight = `${maxHeight}px`;
            scrollElement.style.overflowY = 'auto';
        }

        // 強制的にリフレッシュ
        setTimeout(() => {
            this.editor.refresh();
        }, 100);

        console.log(`✅ CodeMirrorサイズをより大きく設定: ${targetHeight}px (${minHeight}px-${maxHeight}px)`);
    }

    debounce(func, wait) {
        let timeout;
        return (...args) => {
            clearTimeout(timeout);
            timeout = setTimeout(() => func.apply(this, args), wait);
        };
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

    handleInsertText(event) {
        console.log('Handling code-editor:insert-text event')
        const text = event.detail.text
        if (text) {
            this.insertText(text)
        }
    }

    disconnect() {
        // 動的サイズ調整のイベントリスナーを削除
        if (this.resizeHandler) {
            window.removeEventListener('resize', this.resizeHandler);
        }
        if (this.orientationHandler) {
            window.removeEventListener('orientationchange', this.orientationHandler);
        }
        
        // カスタムイベントリスナーを削除
        this.element.removeEventListener('code-editor:insert-text', this.handleInsertText.bind(this))
        
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