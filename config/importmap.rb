# Pin npm packages by running ./bin/importmap

pin "application"

# Stimulus loading とコントローラーのみローカルで管理
pin "@hotwired/stimulus-loading", to: "stimulus-loading.js"
pin_all_from "app/javascript/controllers", under: "controllers"

# Passkey module（ローカルのまま）
pin "passkey"

# CDN配信によるJavaScriptライブラリ（ImportMapで管理）
pin "@hotwired/turbo", to: "https://cdn.jsdelivr.net/npm/@hotwired/turbo@8.0.12/dist/turbo.es2017-esm.js", preload: true
pin "@hotwired/stimulus", to: "https://cdn.jsdelivr.net/npm/@hotwired/stimulus@3.2.2/dist/stimulus.js", preload: true
pin "@rails/activestorage", to: "https://cdn.jsdelivr.net/npm/@rails/activestorage@7.1.502/app/assets/javascripts/activestorage.esm.js", preload: true
pin "spark-md5", to: "https://cdn.jsdelivr.net/npm/spark-md5@3.0.2/spark-md5.min.js", preload: true
pin "codemirror", to: "https://cdn.jsdelivr.net/npm/codemirror@5.65.18/lib/codemirror.js", preload: true
pin "codemirror/mode/markdown/markdown", to: "https://cdn.jsdelivr.net/npm/codemirror@5.65.18/mode/markdown/markdown.js", preload: true
pin "codemirror/mode/javascript/javascript", to: "https://cdn.jsdelivr.net/npm/codemirror@5.65.18/mode/javascript/javascript.js", preload: true
pin "codemirror/mode/xml/xml", to: "https://cdn.jsdelivr.net/npm/codemirror@5.65.18/mode/xml/xml.js", preload: true
pin "codemirror/mode/css/css", to: "https://cdn.jsdelivr.net/npm/codemirror@5.65.18/mode/css/css.js", preload: true
pin "video.js", to: "https://cdn.jsdelivr.net/npm/video.js@8.12.0/dist/video.js", preload: true
pin "bootstrap", to: "https://cdn.jsdelivr.net/npm/bootstrap@5.3.2/dist/js/bootstrap.bundle.min.js", preload: true
