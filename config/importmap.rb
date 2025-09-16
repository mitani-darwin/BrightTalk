# Pin npm packages by running ./bin/importmap

pin "application"
pin "@hotwired/turbo-rails", to: "turbo.min.js"
pin "@hotwired/stimulus", to: "stimulus.min.js"
pin "@hotwired/stimulus-loading", to: "stimulus-loading.js"
pin_all_from "app/javascript/controllers", under: "controllers"

# Passkey module
pin "passkey"

# SparkMD5 for file checksum calculation
pin "spark-md5", to: "spark-md5.min.js"

# CodeMirror for syntax highlighting
pin "codemirror", to: "codemirror.js"
pin "codemirror/mode/markdown/markdown", to: "codemirror/mode/markdown/markdown.js"
pin "codemirror/mode/javascript/javascript", to: "codemirror/mode/javascript/javascript.js"
pin "codemirror/mode/xml/xml", to: "codemirror/mode/xml/xml.js"
pin "codemirror/mode/css/css", to: "codemirror/mode/css/css.js"

# Video.js for enhanced video player
pin "video.js", to: "video.min.js"

pin "@rails/activestorage", to: "activestorage.esm.js"