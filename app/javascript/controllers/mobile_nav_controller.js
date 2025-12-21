import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
  static targets = ["overlay"];

  connect() {
    this.handleKeydown = this.handleKeydown.bind(this);
  }

  open(event) {
    event?.preventDefault();
    if (!this.hasOverlayTarget) return;
    this.overlayTarget.classList.remove("hidden");
    this.overlayTarget.setAttribute("aria-hidden", "false");
    document.addEventListener("keydown", this.handleKeydown);
  }

  close(event) {
    event?.preventDefault();
    if (!this.hasOverlayTarget) return;
    this.overlayTarget.classList.add("hidden");
    this.overlayTarget.setAttribute("aria-hidden", "true");
    document.removeEventListener("keydown", this.handleKeydown);
  }

  handleKeydown(event) {
    if (event.key === "Escape") {
      this.close(event);
    }
  }
}
