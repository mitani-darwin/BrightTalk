# Pin npm packages by running ./bin/importmap

pin "application"

# Stimulus loading とコントローラーのみローカルで管理
pin "@hotwired/stimulus-loading", to: "stimulus-loading.js"
pin_all_from "app/javascript/controllers", under: "controllers"

# Passkey module（ローカルのまま）
pin "passkey"

# CDN配信によるJavaScriptライブラリ（ImportMapで管理）
pin "@hotwired/turbo", to: "https://cdn.jsdelivr.net/npm/@hotwired/turbo@8.0.12/dist/turbo.es2017-esm.js", preload: true
pin "@hotwired/stimulus", to: "https://cdn.skypack.dev/@hotwired/stimulus@3.2.2", preload: true
pin "@rails/activestorage", to: "https://cdn.jsdelivr.net/npm/@rails/activestorage@7.1.502/app/assets/javascripts/activestorage.esm.js", preload: true
pin "spark-md5", to: "https://cdn.skypack.dev/spark-md5@3.0.2", preload: true
pin "codemirror", to: "https://cdn.skypack.dev/codemirror@5.65.18", preload: true
pin "codemirror/mode/markdown/markdown", to: "https://cdn.skypack.dev/codemirror@5.65.18/mode/markdown/markdown", preload: true
pin "codemirror/mode/javascript/javascript", to: "https://cdn.skypack.dev/codemirror@5.65.18/mode/javascript/javascript", preload: true
pin "codemirror/mode/xml/xml", to: "https://cdn.skypack.dev/codemirror@5.65.18/mode/xml/xml", preload: true
pin "codemirror/mode/css/css", to: "https://cdn.skypack.dev/codemirror@5.65.18/mode/css/css", preload: true
pin "video.js", to: "https://cdn.skypack.dev/video.js@8.12.0", preload: true
pin "bootstrap", to: "https://cdn.skypack.dev/bootstrap@5.3.3", preload: true