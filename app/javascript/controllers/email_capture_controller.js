import { Controller } from "@hotwired/stimulus"

// Email capture UX:
// - On submit: disables button + softens copy
// - On Turbo Stream response: server replaces the inner frame with the confirmation state
// - Error rendering happens server-side via the same frame — we never toast errors (CLAUDE.md §3)
export default class extends Controller {
  static targets = ["input", "button", "help"]

  connect() {
    this.element.addEventListener("turbo:submit-start", this.start.bind(this))
    this.element.addEventListener("turbo:submit-end", this.end.bind(this))
  }

  start() {
    if (this.hasButtonTarget) {
      this.buttonTarget.disabled = true
      this.buttonTarget.dataset.originalText = this.buttonTarget.innerHTML
      this.buttonTarget.innerHTML = "Sending…"
    }
  }

  end(event) {
    if (this.hasButtonTarget) {
      this.buttonTarget.disabled = false
      if (this.buttonTarget.dataset.originalText) {
        this.buttonTarget.innerHTML = this.buttonTarget.dataset.originalText
      }
    }

    // If the server returned a non-success status, mark the field with .error
    // (server will also send a Turbo Stream replacing the help line; this is a safety net).
    if (event.detail && event.detail.success === false && this.hasInputTarget) {
      this.inputTarget.classList.add("error")
    }
  }
}
