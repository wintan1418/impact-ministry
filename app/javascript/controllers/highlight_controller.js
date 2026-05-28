import { Controller } from "@hotwired/stimulus"

// Drag-select "Save highlight" UX (CLAUDE.md §5).
// - User drags a selection inside the devotional body.
// - A small floating button appears just above the selection.
// - Clicking it POSTs the range JSON to /highlights.
// - The server responds with a Turbo Stream (preferred) or JSON.
//
// The floating button is appended to <body> so it can sit above any
// scroll-clipped or overflow-hidden container higher up in the tree.
//
// Errors do NOT toast (CLAUDE.md §3). 401 → redirect to /session/new.
export default class extends Controller {
  static targets = ["body"]
  static values = {
    devotionalId: Number,
    endpoint:     { type: String, default: "/highlights" }
  }

  connect() {
    this.csrfToken = document.querySelector('meta[name="csrf-token"]')?.content || ""

    this.onMouseUp     = this.onMouseUp.bind(this)
    this.onTouchEnd    = this.onTouchEnd.bind(this)
    this.onMouseDown   = this.onMouseDown.bind(this)
    this.onKeyDown     = this.onKeyDown.bind(this)
    this.onButtonClick = this.onButtonClick.bind(this)

    this.button = this.buildButton()
    document.body.appendChild(this.button)
    this.button.addEventListener("click", this.onButtonClick)

    this.bodyTarget.addEventListener("mouseup",  this.onMouseUp)
    this.bodyTarget.addEventListener("touchend", this.onTouchEnd)
    document.addEventListener("mousedown", this.onMouseDown)
    document.addEventListener("keydown",   this.onKeyDown)

    this.currentRange = null
  }

  disconnect() {
    if (this.button) {
      this.button.removeEventListener("click", this.onButtonClick)
      this.button.remove()
      this.button = null
    }
    this.bodyTarget.removeEventListener("mouseup",  this.onMouseUp)
    this.bodyTarget.removeEventListener("touchend", this.onTouchEnd)
    document.removeEventListener("mousedown", this.onMouseDown)
    document.removeEventListener("keydown",   this.onKeyDown)
  }

  // --- DOM construction --------------------------------------------------

  buildButton() {
    const btn = document.createElement("button")
    btn.type = "button"
    btn.className = "highlight-save"
    btn.setAttribute("aria-label", "Save this line")
    btn.tabIndex = 0
    btn.innerHTML = `
      <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.8" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true">
        <path d="M19 21l-7-5-7 5V5a2 2 0 0 1 2-2h10a2 2 0 0 1 2 2z"/>
      </svg>
      <span data-label>Save highlight</span>
    `
    return btn
  }

  // --- Selection handling ------------------------------------------------

  onMouseUp(_event)  { this.handleSelection() }
  onTouchEnd(_event) { this.handleSelection() }

  handleSelection() {
    const selection = window.getSelection()
    if (!selection || selection.isCollapsed) {
      this.hideButton()
      return
    }

    const text = selection.toString().trim()
    if (text.length === 0) {
      this.hideButton()
      return
    }

    if (!this.selectionInsideBody(selection)) {
      this.hideButton()
      return
    }

    const range = selection.getRangeAt(0)
    const rect  = range.getBoundingClientRect()
    if (rect.width === 0 && rect.height === 0) {
      this.hideButton()
      return
    }

    // Cache the range. We use a coarse character offset against the body's
    // textContent — good enough for the server-side `excerpt` helper.
    const bodyText = this.bodyTarget.textContent || ""
    const start    = bodyText.indexOf(text)
    const end      = start >= 0 ? start + text.length : text.length

    this.currentRange = { start: start < 0 ? 0 : start, end, text }
    this.showButton(rect)
  }

  selectionInsideBody(selection) {
    const anchor = selection.anchorNode
    const focus  = selection.focusNode
    if (!anchor || !focus) return false
    return this.bodyTarget.contains(anchor) && this.bodyTarget.contains(focus)
  }

  // --- Button position / visibility -------------------------------------

  showButton(rect) {
    const top  = rect.top + window.scrollY - 44
    const left = rect.left + window.scrollX + (rect.width / 2)
    this.button.style.top  = `${top}px`
    this.button.style.left = `${left}px`
    this.button.style.display = "flex"
    this.button.classList.remove("is-saved")
    const label = this.button.querySelector("[data-label]")
    if (label) label.textContent = "Save highlight"
  }

  hideButton() {
    if (!this.button) return
    this.button.style.display = "none"
  }

  onMouseDown(event) {
    if (!this.button) return
    if (this.button.contains(event.target)) return
    if (this.button.style.display !== "none") {
      this.hideButton()
    }
  }

  // Keyboard alternative: Cmd/Ctrl+B with an active selection inside body.
  onKeyDown(event) {
    const isSaveCombo = (event.key === "b" || event.key === "B") && (event.metaKey || event.ctrlKey)
    if (!isSaveCombo) return

    const selection = window.getSelection()
    if (!selection || selection.isCollapsed) return
    if (!this.selectionInsideBody(selection)) return

    event.preventDefault()
    this.handleSelection()
    this.save()
  }

  // --- Save --------------------------------------------------------------

  onButtonClick(event) {
    event.preventDefault()
    this.save()
  }

  async save() {
    if (!this.currentRange) return

    const text_range = JSON.stringify(this.currentRange)

    let response
    try {
      response = await fetch(this.endpointValue, {
        method:  "POST",
        headers: {
          "Accept":       "text/vnd.turbo-stream.html, application/json",
          "Content-Type": "application/json",
          "X-CSRF-Token": this.csrfToken
        },
        body: JSON.stringify({
          devotional_id: this.devotionalIdValue,
          text_range:    text_range
        }),
        credentials: "same-origin"
      })
    } catch (_err) {
      // Network failure — leave the button visible so the user can retry.
      return
    }

    if (response.status === 401) {
      window.location.href = "/session/new"
      return
    }

    if (!response.ok) return

    const contentType = response.headers.get("Content-Type") || ""
    const text        = await response.text()

    if (contentType.includes("turbo-stream") && window.Turbo) {
      window.Turbo.renderStreamMessage(text)
    }

    this.confirmSaved()
  }

  confirmSaved() {
    if (!this.button) return
    const label = this.button.querySelector("[data-label]")
    if (label) label.textContent = "Saved ✓"
    this.button.classList.add("is-saved")

    if (this.confirmTimeout) clearTimeout(this.confirmTimeout)
    this.confirmTimeout = setTimeout(() => {
      this.hideButton()
      this.currentRange = null
      window.getSelection()?.removeAllRanges()
    }, 900)
  }
}
