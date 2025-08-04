# Pin npm packages by running ./bin/importmap

# Rails core JavaScript
pin "application", to: "application.js", preload: true
pin "@hotwired/turbo-rails", to: "turbo.min.js", preload: true
pin "@hotwired/stimulus", to: "stimulus.min.js", preload: true
pin "@hotwired/stimulus-loading", to: "stimulus-loading.js", preload: true

# Stimulus controllers
pin_all_from "app/javascript/controllers", under: "controllers"

# カスタムJavaScriptモジュール
pin "webauthn", to: "webauthn.js"