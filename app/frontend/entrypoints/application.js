console.log('[Vite entry] application.js loaded at', new Date())
import '../stylesheets/application.css'
import '../../javascript/application.js'
if (location.pathname.startsWith('/posts/new')) {
    import('../../javascript/entrypoints/new.js')
}