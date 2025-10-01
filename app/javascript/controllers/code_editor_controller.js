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

        try {
            // 本番環境での確実なCodeMirror取得
            let CodeMirror = window.CodeMirror;

            // 本番環境特有の遅延対応
            if (!CodeMirror && window.loadCodeMirror) {
                console.log('Loading CodeMirror via loadCodeMirror in production...');
                CodeMirror = await window.loadCodeMirror();
            }

            // さらに厳格な待機処理（本番環境用）
            if (!CodeMirror || typeof CodeMirror.fromTextArea !== 'function') {
                console.log('Waiting for CodeMirror in production environment...');
                let retryCount = 0;
                const maxRetries = 30; // 本番環境用に増加

                while (retryCount < maxRetries) {
                    await new Promise(resolve => setTimeout(resolve, 300)); // 待機時間も増加

                    if (window.CodeMirror && typeof window.CodeMirror.fromTextArea === 'function') {
                        CodeMirror = window.CodeMirror;
                        break;
                    }

                    console.log(`CodeMirror wait attempt: ${retryCount + 1}/${maxRetries}`);
                    retryCount++;
                }
            }

            if (!CodeMirror || typeof CodeMirror.fromTextArea !== 'function') {
                throw new Error("CodeMirror is not available in production after waiting");
            }

        } catch (error) {
            console.error("Failed to initialize CodeMirror in production:", error);
            return;
        }

        const textarea = this.textareaTarget || this.element.querySelector('textarea');
        if (!textarea) {
            console.error("Textarea not found in CodeEditor controller");
            return;
        }

        console.log("Found textarea in production:", textarea.id);

        try {
            // 本番環境用のより厳格なCodeMirror初期化
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
                viewportMargin: Infinity, // 本番環境での表示改善
            });

            // 本番環境での確実な初期化確認
            if (this.editor && this.editor.getDoc && this.editor.getWrapperElement) {
                console.log('CodeMirror successfully initialized in production');

                // 本番環境での強制サイズ設定
                const wrapper = this.editor.getWrapperElement();
                if (wrapper) {
                    wrapper.style.height = '600px';
                    wrapper.style.minHeight = '600px';
                    wrapper.style.display = 'block';
                    wrapper.style.visibility = 'visible';
                }

                this.element.classList.remove('codemirror-initializing');
                this.element.classList.add('codemirror-initialized');

                // 初期化完了イベントを発火
                this.dispatch('initialized', { detail: { editor: this.editor } });

                // 本番環境での遅延リフレッシュ
                setTimeout(() => {
                    if (this.editor && this.editor.refresh) {
                        this.editor.refresh();
                        console.log('Production CodeMirror refreshed');
                    }
                }, 500);

            } else {
                console.error('CodeMirror editor creation failed in production');
            }

        } catch (error) {
            console.error('CodeMirror initialization error in production:', error);
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
        console.log('=== CodeEditor insertText called ===');
        console.log('Text to insert:', text);
        console.log('Editor available:', !!this.editor);

        if (this.editor && this.editor.getDoc) {
            const cursor = this.editor.getCursor();
            console.log('Current cursor position:', cursor);

            this.editor.replaceRange(text, cursor);
            this.editor.focus();

            console.log('Text insertion completed successfully');
        } else {
            console.warn('CodeMirror editor not available for text insertion');
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