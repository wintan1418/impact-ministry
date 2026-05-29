import { Controller } from "@hotwired/stimulus"

// Full-screen search overlay.
// - Opened by the 🔍 button in the nav (click->search#open) or Cmd/Ctrl+K.
// - Closed by Escape, the backdrop, or another Turbo navigation.
// - Typing in the input fires a debounced fetch to /search?q=… and replaces
//   the results region with the returned HTML fragment.
// - First open with an empty query pulls a "suggestions" panel so the overlay
//   never looks empty.
//
// Errors never toast (CLAUDE.md §3) — a network failure quietly leaves the
// previous results in place.
export default class extends Controller {
  static targets = ["panel", "input", "results"]
  static values  = { debounce: { type: Number, default: 180 } }

  connect() {
    this.onKeyDown = this.onKeyDown.bind(this)
    // Close on Turbo navigation, but DO NOT preventDefault — that would
    // cancel the navigation itself (which is what broke every link before).
    this.onTurboVisit = () => this.#closeIfOpen()
    document.addEventListener("keydown", this.onKeyDown)
    document.addEventListener("turbo:before-visit", this.onTurboVisit)
    this.loadedInitial = false
    this.debounceTimer = null
  }

  disconnect() {
    document.removeEventListener("keydown", this.onKeyDown)
    document.removeEventListener("turbo:before-visit", this.onTurboVisit)
    if (this.debounceTimer) clearTimeout(this.debounceTimer)
    document.body.style.overflow = ""
  }

  // ---- Open / close --------------------------------------------------------

  open(event) {
    if (event && event.preventDefault) event.preventDefault()
    if (!this.hasPanelTarget) return
    this.panelTarget.classList.add("is-open")
    this.panelTarget.setAttribute("aria-hidden", "false")
    document.body.style.overflow = "hidden"

    // Defer focus until the panel is actually visible — browsers won't focus
    // a hidden input.
    requestAnimationFrame(() => {
      if (this.hasInputTarget) this.inputTarget.focus()
    })

    if (!this.loadedInitial) {
      this.loadedInitial = true
      this.runQuery("")
    }
  }

  // Called via data-action="click->search#close" (event-driven) — guards
  // against cancelling a navigation by only preventing default when the
  // panel was actually open.
  close(event) {
    const wasOpen = this.hasPanelTarget && this.panelTarget.classList.contains("is-open")
    if (event && wasOpen && event.preventDefault) event.preventDefault()
    this.#closeIfOpen()
  }

  #closeIfOpen() {
    if (!this.hasPanelTarget) return
    if (!this.panelTarget.classList.contains("is-open")) return
    this.panelTarget.classList.remove("is-open")
    this.panelTarget.setAttribute("aria-hidden", "true")
    document.body.style.overflow = ""
    if (this.hasInputTarget) this.inputTarget.value = ""
  }

  backdropClose(event) {
    // Only close when the click was on the backdrop itself, not on a child
    // (the card swallows its own clicks via stopPropagation below).
    if (event.target === this.panelTarget) this.close()
  }

  stopPropagation(event) {
    event.stopPropagation()
  }

  // ---- Querying ------------------------------------------------------------

  query() {
    if (this.debounceTimer) clearTimeout(this.debounceTimer)
    this.debounceTimer = setTimeout(() => {
      this.runQuery(this.inputTarget.value)
    }, this.debounceValue)
  }

  async runQuery(value) {
    if (!this.hasResultsTarget) return
    const url = "/search?q=" + encodeURIComponent(value || "")
    let response
    try {
      response = await fetch(url, {
        headers: { "Accept": "text/html" },
        credentials: "same-origin"
      })
    } catch (_err) {
      return // network failure — leave the existing results in place.
    }
    if (!response.ok) return
    const html = await response.text()
    this.resultsTarget.innerHTML = html
  }

  // ---- Global key handling -------------------------------------------------

  onKeyDown(event) {
    // Cmd/Ctrl+K toggles open.
    const isToggle = (event.key === "k" || event.key === "K") && (event.metaKey || event.ctrlKey)
    if (isToggle) {
      event.preventDefault()
      if (this.panelTarget && this.panelTarget.classList.contains("is-open")) {
        this.#closeIfOpen()
      } else {
        this.open()
      }
      return
    }

    // Escape closes when open.
    if (event.key === "Escape" && this.panelTarget && this.panelTarget.classList.contains("is-open")) {
      event.preventDefault()
      this.#closeIfOpen()
    }
  }
}
