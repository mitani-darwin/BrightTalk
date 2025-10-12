// Vite entrypoint for Rails (vite_rails)
// Delegates to the existing application code in app/javascript
// This ensures production builds include CodeMirror and other modules.
import '../stylesheets/application.css'
import '../../javascript/application.js'
