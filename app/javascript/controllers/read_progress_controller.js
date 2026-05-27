import { Controller } from "@hotwired/stimulus"

// Updates a progress bar's width based on how far the user has scrolled
// through the article element. Mount on a wrapper that contains both
// the `.progress` bar (target: bar) and the article (target: article).
export default class extends Controller {
  static targets = ["bar", "article"]

  connect() {
    this.onScroll = this.onScroll.bind(this)
    window.addEventListener("scroll", this.onScroll, { passive: true })
    this.onScroll()
  }

  disconnect() {
    window.removeEventListener("scroll", this.onScroll)
  }

  onScroll() {
    if (!this.hasArticleTarget || !this.hasBarTarget) return
    const el = this.articleTarget
    const rect = el.getBoundingClientRect()
    const top = rect.top + window.scrollY
    const total = Math.max(1, el.offsetHeight - window.innerHeight)
    const visible = window.scrollY - (top - 80)
    const p = Math.max(0, Math.min(1, visible / total))
    this.barTarget.style.width = `${p * 100}%`
  }
}
