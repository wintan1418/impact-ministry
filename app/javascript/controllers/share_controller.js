import { Controller } from "@hotwired/stimulus"

// Quiet "Share this devotional" button.
//   - Mobile: invokes navigator.share with title/url so the OS sheet opens.
//   - Desktop / unsupported: copies the canonical URL to the clipboard and
//     swaps the button label to "Copied" for a moment.
// No toast — feedback is inline per CLAUDE.md §3.
export default class extends Controller {
  static targets = ["label"]
  static values  = { url: String, title: String }

  async share(event) {
    event.preventDefault()
    const url   = this.urlValue || window.location.href
    const title = this.titleValue || document.title

    if (navigator.share) {
      try {
        await navigator.share({ title, url })
        return
      } catch (err) {
        if (err && err.name === "AbortError") return
      }
    }
    await this.#copy(url)
  }

  async #copy(url) {
    try {
      await navigator.clipboard.writeText(url)
      this.#flashLabel("Copied")
    } catch (_err) {
      this.#flashLabel("Press ⌘C")
    }
  }

  #flashLabel(text) {
    if (!this.hasLabelTarget) return
    const original = this.labelTarget.textContent
    this.labelTarget.textContent = text
    this.element.setAttribute("aria-live", "polite")
    setTimeout(() => { this.labelTarget.textContent = original }, 1800)
  }
}
