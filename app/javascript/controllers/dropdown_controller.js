import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="dropdown"
export default class extends Controller {
  static targets = ["button", "menu"]

  connect() {
    this.close = this.close.bind(this)
  }

  toggle() {
    if (this.menuTarget.classList.contains("hidden")) {
      this.open()
    } else {
      this.close()
    }
  }

  open() {
    this.menuTarget.classList.remove("hidden")
    document.addEventListener("click", this.close)
  }

  close(event) {
    if (event && this.element.contains(event.target)) {
      return
    }
    
    this.menuTarget.classList.add("hidden")
    document.removeEventListener("click", this.close)
  }

  disconnect() {
    document.removeEventListener("click", this.close)
  }
}