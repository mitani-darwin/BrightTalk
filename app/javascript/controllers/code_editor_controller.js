import { EditorView } from '@codemirror/view'
import { basicSetup } from 'codemirror'
import { Controller } from "@hotwired/stimulus"
import { EditorState } from '@codemirror/state'
import { markdown } from '@codemirror/lang-markdown'
import { tags as t } from '@lezer/highlight'
import { HighlightStyle, syntaxHighlighting } from '@codemirror/language'

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

        // カスタムイベントリスナーを追加（改良版）
        this.boundInsertHandler = this.handleInsertText.bind(this);
        this.element.addEventListener('code-editor:insert-text', this.boundInsertHandler);
   }

    async initializeCodeMirror() {
        // 初期化フラグを設定
        this.element.classList.add('codemirror-initializing')

        const textarea = this.textareaTarget || this.element.querySelector('textarea');
        if (!textarea) {
            console.error("Textarea not found in CodeEditor controller");
            return;
        }

        console.log("Found textarea:", textarea.id || '(no id)');

        try {
            // 静的インポートに変更：必要なモジュールはファイル先頭で import 済み

            // CM6 HighlightStyle 定義（Markdown と一般コードトークン）
            const mdHighlight = HighlightStyle.define([
                // Markdown headings: Light blue
                { tag: t.heading,  color: '#4fc3f7', fontWeight: 'bold' },
                { tag: t.heading1, color: '#4fc3f7', fontWeight: 'bold' },
                { tag: t.heading2, color: '#4fc3f7', fontWeight: 'bold' },
                { tag: t.heading3, color: '#4fc3f7', fontWeight: 'bold' },
                { tag: t.heading4, color: '#4fc3f7', fontWeight: 'bold' },
                { tag: t.heading5, color: '#4fc3f7', fontWeight: 'bold' },
                { tag: t.heading6, color: '#4fc3f7', fontWeight: 'bold' },

                // Emphasis/Bold/Italic
                { tag: t.strong,   color: '#81c784', fontWeight: 'bold' },
                { tag: t.emphasis, color: '#ffb74d', fontStyle: 'italic' },
                { tag: t.strikethrough, textDecoration: 'line-through', color: '#ef5350' },

                // Links
                { tag: t.link,     color: '#64b5f6', textDecoration: 'underline' },
                { tag: t.url,      color: '#64b5f6', textDecoration: 'underline' },

                // Quotes and lists
                { tag: t.quote,    color: '#a5d6a7', fontStyle: 'italic' },
                { tag: t.list,     color: '#ce93d8' },

                // Inline/Block code appearance
                { tag: t.code,     color: '#ff8a65', backgroundColor: 'rgba(255, 255, 255, 0.1)', padding: '2px 4px', borderRadius: '3px' },

                // Fenced code common tokens
                { tag: t.keyword,       color: '#8e44ad', fontWeight: 'bold' },
                { tag: t.atom,          color: '#d35400' },
                { tag: t.number,        color: '#e74c3c' },
                { tag: t.definition,    color: '#2c3e50' },
                { tag: t.variableName,  color: '#27ae60' },
                { tag: t.typeName,      color: '#3498db' },
                { tag: t.propertyName,  color: '#16a085' },
                { tag: t.operator,      color: '#95a5a6' },
                { tag: t.comment,       color: '#95a5a6', fontStyle: 'italic' },
                { tag: t.string,        color: '#27ae60' },
                { tag: t.meta,          color: '#34495e' },
                { tag: t.tagName,       color: '#e74c3c' },
                { tag: t.attributeName, color: '#3498db' },
            ]);

            const state = EditorState.create({
                doc: textarea.value,
                extensions: [
                    basicSetup,
                    markdown({
                        codeLanguages: ['javascript', 'python', 'ruby', 'html', 'css', 'sql'],
                        addKeymap: true
                    }),
                    syntaxHighlighting(mdHighlight),
                    EditorView.lineWrapping,
                    EditorView.theme({
                        '&': {
                            fontSize: '14px',
                            fontFamily: 'Monaco, "Lucida Console", monospace'
                        },
                        '.cm-content': { padding: '16px', minHeight: '300px' },
                        '.cm-focused': { outline: '2px solid #0d6efd' },
                        '.cm-editor': { border: '1px solid #ced4da', borderRadius: '0.375rem' },
                    }),
                    EditorView.updateListener.of((update) => {
                        if (update.docChanged) {
                            textarea.value = update.state.doc.toString();
                            textarea.dispatchEvent(new Event('input', { bubbles: true }));
                        }
                    })
                ]
            });

            this.editor = new EditorView({ state, parent: textarea.parentNode });

            // テキストエリアを非表示にする
            textarea.style.display = 'none';

            if (this.editor && this.editor.dom) {
                console.log('CodeMirror 6 successfully initialized with static imports');
                this.element.classList.remove('codemirror-initializing');
                this.element.classList.add('codemirror-initialized');
                this.dispatch('initialized', { detail: { editor: this.editor } });
            } else {
                console.error('CodeMirror 6 editor creation failed');
            }
        } catch (error) {
            console.error('CodeMirror initialization error (static import):', error);

            // フォールバック（任意）: 既存の window.CodeMirror を試す
            try {
                const CM = window.CodeMirror || (window.loadCodeMirror ? await window.loadCodeMirror() : null);
                if (!CM) throw new Error('Fallback CodeMirror not available');

                const { EditorView, EditorState, basicSetup, markdown, HighlightStyle, tags: t, syntaxHighlighting } = CM;
                const mdHighlight = HighlightStyle && HighlightStyle.define ? HighlightStyle.define([]) : null;

                const state = EditorState.create({
                    doc: textarea.value,
                    extensions: [
                        basicSetup,
                        markdown({ addKeymap: true }),
                        ...(mdHighlight ? [syntaxHighlighting(mdHighlight)] : []),
                    ]
                });
                this.editor = new EditorView({ state, parent: textarea.parentNode });
                textarea.style.display = 'none';
                this.element.classList.remove('codemirror-initializing');
                this.element.classList.add('codemirror-initialized');
                this.dispatch('initialized', { detail: { editor: this.editor } });
            } catch (fallbackErr) {
                console.error('Fallback CodeMirror initialization also failed:', fallbackErr);
            }
        }
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