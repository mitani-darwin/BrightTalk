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

        // グローバル参照を作成（デバッグ用）
        if (!window.codeEditorInstances) {
            window.codeEditorInstances = new Map();
        }
        window.addEventListener('resize', this.resizeHandler);

        this.resizeHandler = this.debounce(() => {
            this.adjustEditorSize();
        }, 150);

        // カスタムイベントリスナーを追加（改良版）
        this.boundInsertHandler = this.handleInsertText.bind(this);
        this.element.addEventListener('code-editor:insert-text', this.boundInsertHandler);
   }

    async initializeCodeMirror() {
        // 初期化フラグを設定
        this.element.classList.add('codemirror-initializing')

        try {
            // CodeMirror 6の確実な取得
            let CodeMirror = window.CodeMirror;

            // 本番環境特有の遅延対応
            if (!CodeMirror && window.loadCodeMirror) {
                console.log('Loading CodeMirror 6 via loadCodeMirror in production...');
                CodeMirror = await window.loadCodeMirror();
            }

            // CodeMirror 6の待機処理
            if (!CodeMirror || !CodeMirror.EditorView || !CodeMirror.EditorState) {
                console.log('Waiting for CodeMirror 6 in production environment...');
                let retryCount = 0;
                const maxRetries = 30;

                while (retryCount < maxRetries) {
                    await new Promise(resolve => setTimeout(resolve, 300));

                    if (window.CodeMirror && window.CodeMirror.EditorView && window.CodeMirror.EditorState) {
                        CodeMirror = window.CodeMirror;
                        break;
                    }

                    console.log(`CodeMirror 6 wait attempt: ${retryCount + 1}/${maxRetries}`);
                    retryCount++;
                }
            }

            if (!CodeMirror || !CodeMirror.EditorView || !CodeMirror.EditorState) {
                throw new Error("CodeMirror 6 is not available in production after waiting");
            }

        } catch (error) {
            console.error("Failed to initialize CodeMirror 6 in production:", error);
            return;
        }

        const textarea = this.textareaTarget || this.element.querySelector('textarea');
        if (!textarea) {
            console.error("Textarea not found in CodeEditor controller");
            return;
        }

        console.log("Found textarea in production:", textarea.id);

        try {
            // CodeMirror 6の初期化
            const { EditorView, EditorState, basicSetup, markdown } = CodeMirror;
            
            const state = EditorState.create({
                doc: textarea.value,
                extensions: [
                    basicSetup,
                    markdown(),
                    EditorView.lineWrapping,
                    EditorView.updateListener.of((update) => {
                        if (update.docChanged) {
                            textarea.value = update.state.doc.toString();
                            textarea.dispatchEvent(new Event('input', { bubbles: true }));
                        }
                    })
                ]
            });

            this.editor = new EditorView({
                state,
                parent: textarea.parentNode
            });
            
            // テキストエリアを非表示にする
            textarea.style.display = 'none';

            // CodeMirror 6での確実な初期化確認
            if (this.editor && this.editor.dom) {
                console.log('CodeMirror 6 successfully initialized in production');

                this.element.classList.remove('codemirror-initializing');
                this.element.classList.add('codemirror-initialized');

                // 初期化完了イベントを発火
                this.dispatch('initialized', { detail: { editor: this.editor } });

                console.log('CodeMirror 6 initialization completed');

            } else {
                console.error('CodeMirror 6 editor creation failed in production');
            }

            this.adjustEditorSize();
        } catch (error) {
            console.error('CodeMirror initialization error in production:', error);
        }
    }

    adjustEditorSize() {
        // エディターが初期化されているかチェック
        if (!this.editor || !this.editor.dom) return;

        const viewportHeight = window.innerHeight;
        const buttonAreaHeight = 100; // ボタンエリア（投稿・キャンセルボタン）
        const headerHeight = this.getEstimatedHeaderHeight(); // ヘッダー・タイトル部分
        const safetyMargin = this.getDeviceSpecificAdjustments().safetyMargin; // 安全余白

        // 利用可能な高さを計算
        const availableHeight = (viewportHeight - buttonAreaHeight - headerHeight - safetyMargin) * 0.6;

        console.log('Viewport height:', viewportHeight);
        console.log('Button area height:', buttonAreaHeight);
        console.log('Header height:', headerHeight);
        console.log('Safety margin:', safetyMargin);
        console.log('Available viewport height:', availableHeight);

        // CodeMirror 6のAPIを使用してエディターサイズを調整
        const editorDom = this.editor.dom;
        if (editorDom) {
            editorDom.style.maxHeight = `${availableHeight}px`;
            editorDom.style.height = `${availableHeight}px`;
            editorDom.style.width = '100%';
        }
    }

    getEstimatedHeaderHeight() {
        const navbar = document.querySelector('.navbar, nav, header');
        return navbar ? navbar.offsetHeight + 20 : 80;
    }

    getDeviceSpecificAdjustments() {
        const isMobile = /Android|webOS|iPhone|iPad|iPod|BlackBerry|IEMobile|Opera Mini/i.test(navigator.userAgent);

        return {
            safetyMargin: isMobile ? 40 : 20,
            maxContentRatio: isMobile ? 0.5 : 0.6
        };
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

        if (this.editor && this.editor.state) {
            const cursor = this.editor.state.selection.main.head;
            console.log('Current cursor position:', cursor);

            const transaction = this.editor.state.update({
                changes: { from: cursor, insert: text }
            });
            
            this.editor.dispatch(transaction);
            this.editor.focus();

            console.log('Text insertion completed successfully');
        } else {
            console.warn('CodeMirror 6 editor not available for text insertion');
        }
    }


    handleInsertText(event) {
        console.log('=== CodeEditor received insert-text event ===');
        const text = event.detail.text;
        if (text) {
            console.log('Inserting text via event:', text);
            this.insertText(text);

            // 成功イベントを発火
            this.dispatch('text-inserted', {detail: {text: text}});
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

        // イベントリスナーを削除
        if (this.boundInsertHandler) {
            this.element.removeEventListener('code-editor:insert-text', this.boundInsertHandler);
        }

        // グローバル参照を削除
        if (window.codeEditorInstances) {
            window.codeEditorInstances.delete(this.element);
        }
    }
}