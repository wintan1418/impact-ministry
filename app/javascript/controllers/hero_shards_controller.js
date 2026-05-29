import { Controller } from "@hotwired/stimulus"

// Hero "breaking-glass" slideshow.
//   - Cycles through N images on a fixed interval.
//   - Outgoing slide animates a clip-path "shatter" — the rectangle
//     collapses into a jagged cluster while a sheen sweeps across.
//   - Incoming slide cross-fades up underneath.
//   - Caption (kicker + title) crossfades to match the active slide.
//   - Honors prefers-reduced-motion (no transform, plain opacity swap).
export default class extends Controller {
  static targets = ["slide", "kicker", "title"]
  static values  = { interval: { type: Number, default: 4400 } }

  connect() {
    this.index = 0
    if (this.slideTargets.length < 2) return

    this.reducedMotion = window.matchMedia("(prefers-reduced-motion: reduce)").matches
    this.timer = setInterval(() => this.advance(), this.intervalValue)

    // Pause when hover/focus is on the carousel, resume on leave.
    this.element.addEventListener("mouseenter", this.pause.bind(this))
    this.element.addEventListener("mouseleave", this.resume.bind(this))
    this.element.addEventListener("focusin",   this.pause.bind(this))
    this.element.addEventListener("focusout",  this.resume.bind(this))
  }

  disconnect() {
    if (this.timer) clearInterval(this.timer)
  }

  pause() {
    if (this.timer) { clearInterval(this.timer); this.timer = null }
  }

  resume() {
    if (this.timer || this.reducedMotion) return
    this.timer = setInterval(() => this.advance(), this.intervalValue)
  }

  advance() {
    const slides = this.slideTargets
    const total  = slides.length
    if (total < 2) return

    const current = slides[this.index]
    this.index    = (this.index + 1) % total
    const next    = slides[this.index]

    current.classList.add("is-exiting")
    current.classList.remove("is-active")
    current.setAttribute("aria-hidden", "true")

    next.classList.add("is-active")
    next.setAttribute("aria-hidden", "false")

    if (this.hasKickerTarget) this.#fadeText(this.kickerTarget, next.dataset.kicker || "")
    if (this.hasTitleTarget)  this.#fadeText(this.titleTarget,  next.dataset.title  || "")

    // Drop the exit class after the animation finishes so the slide is
    // ready to come around again on the next loop.
    setTimeout(() => current.classList.remove("is-exiting"), 900)
  }

  #fadeText(el, value) {
    if (!el || el.textContent === value) return
    el.style.opacity = "0"
    setTimeout(() => {
      el.textContent = value
      el.style.opacity = "1"
    }, 220)
  }
}
