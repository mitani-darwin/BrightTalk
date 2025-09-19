# Pin npm packages by running ./bin/importmap

pin "application"

# Stimulus loading とコントローラーのみローカルで管理
pin "@hotwired/stimulus-loading", to: "stimulus-loading.js"
pin_all_from "app/javascript/controllers", under: "controllers"

# Passkey module（ローカルのまま）
pin "passkey"

# CDN libraries are loaded via direct script tags in application.html.erb