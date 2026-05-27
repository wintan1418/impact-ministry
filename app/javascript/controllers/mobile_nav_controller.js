import { Controller } from "@hotwired/stimulus"

// Toggles the mobile menu drawer + swaps the hamburger/close icons.
// Closes on Turbo navigation so the next page boots with the drawer shut.
export default class extends Controller {
  static targets = ["menu", "button", "iconOpen", "iconClose"]

  connect() {
    this.close = this.close.bind(this)
    document.addEventListener("turbo:before-visit", this.close)
    document.addEventListener("turbo:load", this.close)
  }

  disconnect() {
    document.removeEventListener("turbo:before-visit", this.close)
    document.removeEventListener("turbo:load", this.close)
  }

  toggle() {
    const open = this.menuTarget.classList.toggle("hidden") === false
    this.buttonTarget.setAttribute("aria-expanded", open ? "true" : "false")
    this.buttonTarget.setAttribute("aria-label", open ? "Close menu" : "Open menu")
    if (this.hasIconOpenTarget && this.hasIconCloseTarget) {
      this.iconOpenTarget.classList.toggle("hidden", open)
      this.iconCloseTarget.classList.toggle("hidden", !open)
    }
    document.body.style.overflow = open ? "hidden" : ""
  }

  close() {
    if (!this.menuTarget.classList.contains("hidden")) {
      this.menuTarget.classList.add("hidden")
      this.buttonTarget.setAttribute("aria-expanded", "false")
      this.buttonTarget.setAttribute("aria-label", "Open menu")
      if (this.hasIconOpenTarget && this.hasIconCloseTarget) {
        this.iconOpenTarget.classList.remove("hidden")
        this.iconCloseTarget.classList.add("hidden")
      }
      document.body.style.overflow = ""
    }
  }
}
