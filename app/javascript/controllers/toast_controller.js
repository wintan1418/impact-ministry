import { Controller } from "@hotwired/stimulus"

// Global toast — top-center cream + hairline. Used ONLY for async confirmations
// (e.g. "Highlight saved"). Errors NEVER toast (CLAUDE.md §3).
//
// Trigger from anywhere:
//   window.dispatchEvent(new CustomEvent("toast:show", { detail: { message: "Saved." } }))
export default class extends Controller {
  static values = { duration: { type: Number, default: 2400 } }

  connect() {
    this.show = this.show.bind(this)
    window.addEventListener("toast:show", this.show)
  }

  disconnect() {
    window.removeEventListener("toast:show", this.show)
    if (this.timeout) clearTimeout(this.timeout)
  }

  show(event) {
    const message = event.detail && event.detail.message
    if (!message) return
    this.element.textContent = message
    this.element.classList.add("toast-show")
    if (this.timeout) clearTimeout(this.timeout)
    this.timeout = setTimeout(() => this.element.classList.remove("toast-show"), this.durationValue)
  }
}
