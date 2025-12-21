import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
  static targets = ["overlay", "panel", "trigger"];

  connect() {
    this.handleKeydown = this.handleKeydown.bind(this);
  }

  open(event) {
    event?.preventDefault();
    if (!this.hasOverlayTarget) return;
    this.overlayTarget.classList.remove("hidden");
    this.overlayTarget.setAttribute("aria-hidden", "false");
    if (this.hasTriggerTarget) {
      this.triggerTarget.setAttribute("aria-expanded", "true");
    }
    document.body.classList.add("overflow-hidden");
    document.addEventListener("keydown", this.handleKeydown);
    if (this.hasPanelTarget) {
      requestAnimationFrame(() => this.panelTarget.focus());
    }
  }

  close(event) {
    event?.preventDefault();
    if (!this.hasOverlayTarget) return;
    this.overlayTarget.classList.add("hidden");
    this.overlayTarget.setAttribute("aria-hidden", "true");
    if (this.hasTriggerTarget) {
      this.triggerTarget.setAttribute("aria-expanded", "false");
    }
    document.body.classList.remove("overflow-hidden");
    document.removeEventListener("keydown", this.handleKeydown);
  }

  handleKeydown(event) {
    if (event.key === "Escape") {
      this.close(event);
    }
  }
}
