# Pin npm packages by running ./bin/importmap

pin "application"

# Stimulus loading とコントローラーのみローカルで管理
pin "@hotwired/stimulus-loading", to: "stimulus-loading.js"
pin_all_from "app/javascript/controllers", under: "controllers"

# Passkey module（ローカルのまま）
pin "passkey"

# Active Storage - CloudFrontから配信
pin "@rails/activestorage", to: "#{ENV['CLOUDFRONT_JAVASCRIPT_URL']}/activestorage.esm.js", preload: true

# CloudFrontから配信するJavaScriptライブラリ
base_url = ENV['CLOUDFRONT_JAVASCRIPT_URL'] || "/assets"

pin "@hotwired/turbo", to: "#{base_url}/turbo.min.js"
pin "@hotwired/stimulus", to: "#{base_url}/stimulus.min.js"
pin "spark-md5", to: "#{base_url}/spark-md5.min.js"
pin "codemirror", to: "#{base_url}/codemirror.js"
pin "codemirror/mode/markdown/markdown", to: "#{base_url}/codemirror-markdown.js"
pin "codemirror/mode/javascript/javascript", to: "#{base_url}/codemirror-javascript.js"
pin "codemirror/mode/xml/xml", to: "#{base_url}/codemirror-xml.js"
pin "codemirror/mode/css/css", to: "#{base_url}/codemirror-css.js"
pin "video.js", to: "#{base_url}/video.min.js"
pin "bootstrap", to: "#{base_url}/bootstrap.bundle.min.js"