import { EditorView } from '@codemirror/view'
import { basicSetup } from 'codemirror'
import { Controller } from "@hotwired/stimulus"
import { markdown } from '@codemirror/lang-markdown'
import { HighlightStyle, syntaxHighlighting } from '@codemirror/language'
import { tags as t } from '@lezer/highlight'

export default class extends Controller {
    static targets = ["textarea"]

    connect() {
        // 可視状態なら即初期化、そうでなければ次フレームで再確認
        if (this.cm) return
        const start = () => this.initializeCodeMirror()
        const isVisible = (el) => {
            if (!el) return false
            const style = getComputedStyle(el)
            if (style.display === 'none' || style.visibility === 'hidden') return false
            if (!el.offsetParent && style.position !== 'fixed') return false
            return true
        }
        if (document.head && this.element.isConnected && isVisible(this.element)) {
            start()
        } else {
            requestAnimationFrame(() => {
                if (document.head && this.element.isConnected && isVisible(this.element)) start()
            })
        }
    }

    async initializeCodeMirror() {
        // 既存の初期化までは同じ
        const textarea = this.textareaTarget || this.element.querySelector('textarea')
        if (!textarea) return

        // CodeMirror v5 デフォルト風の配色（できる限り近づけた近似）
        const cm5Theme = EditorView.theme({
            '&': { color: '#000', backgroundColor: '#fff' },
            '.cm-content': { caretColor: '#000' },
            '.cm-cursor, .cm-dropCursor': { borderLeft: '1px solid #000' },
            '&.cm-focused .cm-selectionBackground, .cm-selectionBackground, ::selection': {
                backgroundColor: '#d9d9d9'
            },
            '.cm-gutters': {
                backgroundColor: '#f7f7f7',
                color: '#999',
                borderRight: '1px solid #ddd'
            }
        }, { dark: false })

        // Editor size/scroll: add vertical scrollbar by constraining height
        const fixedHeightTheme = EditorView.theme({
            '&': { maxHeight: '60vh' },
            '.cm-scroller': { overflowY: 'auto' }
        })

        // 既存の cm5Highlight 定義の直前・または直上に追記
        const headingTags = [
            t.heading,
            t.heading1, t.heading2, t.heading3, t.heading4, t.heading5, t.heading6
        ].filter(Boolean) // 未定義要素を除外

        if (t.headingMark) headingTags.push(t.headingMark) // 存在すれば追加

        const cm5Highlight = HighlightStyle.define([
            { tag: headingTags, color: '#00f' },
            { tag: t.keyword, color: '#708' },          // .cm-keyword
            { tag: t.atom, color: '#219' },             // .cm-atom
            { tag: t.number, color: '#164' },           // .cm-number
            { tag: t.definition(t.variableName), color: '#00f' }, // .cm-def
            { tag: t.variableName, color: '#000' },     // .cm-variable
            { tag: t.propertyName, color: '#00c' },     // .cm-property
            { tag: t.typeName, color: '#085' },         // .cm-variable-3 近似
            { tag: t.className, color: '#05a' },        // .cm-variable-2 近似
            { tag: t.string, color: '#a11' },           // .cm-string
            { tag: t.special(t.string), color: '#f50' },// .cm-string-2
            { tag: t.comment, color: '#a50' },          // .cm-comment
            { tag: t.meta, color: '#555' },             // .cm-meta / .cm-qualifier
            { tag: t.link, color: '#00c', textDecoration: 'underline' }, // .cm-link
            { tag: t.tagName, color: '#170' },          // .cm-tag
            { tag: t.attributeName, color: '#00c' },    // .cm-attribute
            { tag: t.bracket, color: '#997' },          // .cm-bracket
            { tag: t.contentSeparator, color: '#888' }, // Markdown horizontal rule ("---")

            // --- Markdown (CM5 default-like) ---
            // Headers (including the leading '#') — CM5 .cm-header is blue
            // Blockquote — CM5 .cm-quote is green
            { tag: t.quote, color: '#090' },
            // Emphasis/Bold/Strike — CM5 changes font style rather than color
            { tag: t.strong, fontWeight: 'bold' },
            { tag: t.emphasis, fontStyle: 'italic' },
            { tag: t.strikethrough, textDecoration: 'line-through' },

            { tag: t.invalid, color: '#f00' }           // .cm-error
        ])

        // CodeMirror → textarea の内容同期（入力のたび同期）
        const syncToTextarea = EditorView.updateListener.of((update) => {
            if (update.docChanged) {
                textarea.value = update.state.doc.toString()
            }
        })

        const baseExtensions = [
            basicSetup,
            markdown(),
            cm5Theme,
            fixedHeightTheme,
            // Use our highlight style with normal precedence so it applies
            syntaxHighlighting(cm5Highlight),
            syncToTextarea,
        ]

        // テキストエリアの直前に CodeMirror 用コンテナを挿入（置換表示）
        const cmContainer = document.createElement('div')
        cmContainer.className = 'cm-container'
        textarea.parentElement.insertBefore(cmContainer, textarea)

        this.cm = new EditorView({
            doc: textarea.value || '',
            parent: cmContainer,
            extensions: baseExtensions,
        })

        // textarea は送信用に保持しつつ非表示にする
        textarea.hidden = true
        textarea.setAttribute('aria-hidden', 'true')

        // 念のため初期同期
        textarea.value = this.cm.state.doc.toString()

        // フォーム送信直前にも最終同期
        const form = textarea.closest('form')
        if (form && !this._syncedOnSubmit) {
            this._syncedOnSubmit = true
            form.addEventListener('submit', () => {
                textarea.value = this.cm.state.doc.toString()
            })
        }

        // insertText 等で利用する参照（後方互換）
        this.editor = this.cm

        // カスタムイベントでのテキスト挿入（フォーム側からの依頼に対応）
        if (!this.boundInsertHandler) {
            this.boundInsertHandler = this.handleInsertText.bind(this)
            this.element.addEventListener('code-editor:insert-text', this.boundInsertHandler)
        }

        // 初期化完了の通知とフラグ設定（ページ側の確認ロジック向け）
        this.dispatch('ready', { detail: { view: this.cm } })
        // 互換目的: 以前のリスナー向けイベント名も発火
        this.dispatch('initialized', { detail: { view: this.cm } })
        this.element.dataset.codemirrorReady = 'true'
        this.element.classList.add('codemirror-initialized')
        if (!window.codeEditorInstances) window.codeEditorInstances = new WeakMap()
        window.codeEditorInstances.set(this.element, this.cm)

        // Safari 安定化のため、レイアウト確定後に軽くフォーカス同期（副作用なし）
        queueMicrotask(() => requestAnimationFrame(() => { /* noop */ }))
    }

    isVisible(el) {
        if (!el) return false
        const style = getComputedStyle(el)
        if (style.display === 'none' || style.visibility === 'hidden') return false
        // display:none 親のケースにも一部対応
        if (!el.offsetParent && style.position !== 'fixed') return false
        return true
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
        // EditorView を破棄し参照をクリア
        try { this.cm?.destroy() } finally { this.cm = null }
        this.editor = null

        // 動的サイズ調整のイベントリスナーを削除
        if (this.resizeHandler) {
            window.removeEventListener('resize', this.resizeHandler)
        }
        if (this.orientationHandler) {
            window.removeEventListener('orientationchange', this.orientationHandler)
        }

        // カスタムイベントリスナー（事前にバインド済みの場合のみ）を削除
        if (this.boundInsertHandler) {
            this.element.removeEventListener('code-editor:insert-text', this.boundInsertHandler)
            this.boundInsertHandler = null
        }

        // グローバル参照を削除
        if (window.codeEditorInstances) {
            window.codeEditorInstances.delete(this.element)
        }

        // 状態フラグを戻す
        if (this.element && this.element.dataset) {
            delete this.element.dataset.codemirrorReady
        }
    }
}