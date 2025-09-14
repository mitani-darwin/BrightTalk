# Pin npm packages by running ./bin/importmap

pin "application"
pin "@hotwired/turbo-rails", to: "turbo.min.js"
pin "@hotwired/stimulus", to: "stimulus.min.js"
pin "@hotwired/stimulus-loading", to: "stimulus-loading.js"
pin_all_from "app/javascript/controllers", under: "controllers"

# Passkey module
pin "passkey"

# SparkMD5 for file checksum calculation
pin "spark-md5", to: "https://cdn.jsdelivr.net/npm/spark-md5@3.0.2/spark-md5.min.js"

# Active Storage Direct Upload
pin "@rails/activestorage", to: "activestorage.esm.js"

# CodeMirror for syntax highlighting
pin "codemirror", to: "https://cdn.jsdelivr.net/npm/codemirror@5.65.16/lib/codemirror.js"
pin "codemirror/mode/markdown/markdown", to: "https://cdn.jsdelivr.net/npm/codemirror@5.65.16/mode/markdown/markdown.js"
pin "codemirror/mode/javascript/javascript", to: "https://cdn.jsdelivr.net/npm/codemirror@5.65.16/mode/javascript/javascript.js"
pin "codemirror/mode/xml/xml", to: "https://cdn.jsdelivr.net/npm/codemirror@5.65.16/mode/xml/xml.js"
pin "codemirror/mode/css/css", to: "https://cdn.jsdelivr.net/npm/codemirror@5.65.16/mode/css/css.js"
