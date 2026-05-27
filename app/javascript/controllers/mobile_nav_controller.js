import { Controller } from "@hotwired/stimulus"

// Toggles the mobile menu drawer + swaps the hamburger/close icons.
// Drawer visibility is driven by `.is-open` on the menu element (CSS rules
// in application.tailwind.css handle the display switch + the 880px media
// query that hides the desktop nav-links).
//
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
    const open = !this.menuTarget.classList.contains("is-open")
    this.menuTarget.classList.toggle("is-open", open)
    this.buttonTarget.setAttribute("aria-expanded", open ? "true" : "false")
    this.buttonTarget.setAttribute("aria-label", open ? "Close menu" : "Open menu")
    if (this.hasIconOpenTarget && this.hasIconCloseTarget) {
      this.iconOpenTarget.style.display  = open ? "none" : ""
      this.iconCloseTarget.style.display = open ? ""    : "none"
    }
    document.body.style.overflow = open ? "hidden" : ""
  }

  close() {
    if (!this.menuTarget.classList.contains("is-open")) return
    this.menuTarget.classList.remove("is-open")
    this.buttonTarget.setAttribute("aria-expanded", "false")
    this.buttonTarget.setAttribute("aria-label", "Open menu")
    if (this.hasIconOpenTarget && this.hasIconCloseTarget) {
      this.iconOpenTarget.style.display  = ""
      this.iconCloseTarget.style.display = "none"
    }
    document.body.style.overflow = ""
  }
}
