
// Configure your import map in config/importmap.rb. Read more: https://github.com/rails/importmap-rails
import "@hotwired/turbo-rails"
import "controllers"

// WebAuthn機能が必要なページでのみ動的読み込み
if (document.querySelector('[data-controller="webauthn"]') ||
    location.pathname.includes('/webauthn_') ||
    location.pathname.includes('/users/sign_in')) {
    import("webauthn").then(module => {
        console.log("WebAuthn module loaded successfully");
    }).catch(error => {
        console.error("Failed to load WebAuthn module:", error);
    });
}