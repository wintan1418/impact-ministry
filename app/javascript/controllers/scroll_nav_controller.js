import { Controller } from "@hotwired/stimulus"

// Adds `.nav-scrolled` once the user scrolls past the hero (~64px).
// Triggers cream background + hairline border on the sticky nav.
export default class extends Controller {
  static values = { threshold: { type: Number, default: 64 } }

  connect() {
    this.update = this.update.bind(this)
    window.addEventListener("scroll", this.update, { passive: true })
    this.update()
  }

  disconnect() {
    window.removeEventListener("scroll", this.update)
  }

  update() {
    if (window.scrollY > this.thresholdValue) {
      this.element.classList.add("nav-scrolled")
    } else {
      this.element.classList.remove("nav-scrolled")
    }
  }
}
