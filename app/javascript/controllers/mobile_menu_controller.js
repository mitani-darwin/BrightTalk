import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="mobile-menu"
export default class extends Controller {
  static targets = ["menu", "openIcon", "closeIcon"]

  toggle() {
    if (this.menuTarget.classList.contains("hidden")) {
      this.open()
    } else {
      this.close()
    }
  }

  open() {
    this.menuTarget.classList.remove("hidden")
    this.openIconTarget.classList.add("hidden")
    this.closeIconTarget.classList.remove("hidden")
  }

  close() {
    this.menuTarget.classList.add("hidden")
    this.openIconTarget.classList.remove("hidden")
    this.closeIconTarget.classList.add("hidden")
  }
}