// app/javascript/entrypoints/new.js
import '../passkey'

// CodeMirror 初期化完了イベントを受け取り、フォールバック確認の誤検知を防ぐ
if (typeof window !== 'undefined') {
  window.__cmReady = false
  document.addEventListener('code-editor:ready', (e) => {
    // フラグを立て、必要なら参照を保持（デバッグ用途）
    window.__cmReady = true
    window.__cmView = e?.detail?.view || null
    // console.debug('[new] CodeMirror ready event received', window.__cmView)
  })

  // 後追い確認（イベントを聞き逃した場合でも DOM のフラグ/参照で確定）
  queueMicrotask?.(() => {
    const el = document.querySelector('[data-controller~="code-editor"]')
    if (!window.__cmReady && el) {
      if (el.dataset.codemirrorReady === 'true') window.__cmReady = true
      if (!window.__cmReady && window.codeEditorInstances) {
        const v = window.codeEditorInstances.get(el)
        if (v) {
          window.__cmReady = true
          window.__cmView = v
        }
      }
    }
  })
}
