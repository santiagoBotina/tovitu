import { Controller } from "@hotwired/stimulus"

// Drives the "Ready to meet someone?" featured-pets carousel on the landing
// page. The prev/next arrows scroll the strip by one "card + gap" step so the
// CTA card at the end stays reachable. Arrows are hidden on touch devices via
// CSS (display:none, so they are also out of the tab order) and reflect
// reachability through the disabled attribute.
export default class extends Controller {
  static targets = ["strip", "prevButton", "nextButton"]

  connect() {
    this.reducedMotion = window.matchMedia("(prefers-reduced-motion: reduce)").matches
    if (!this.hasStripTarget) return

    this.stripTarget.addEventListener("scroll", this.updateButtons, { passive: true })
    window.addEventListener("resize", this.updateButtons)
    this.updateButtons()
  }

  disconnect() {
    if (!this.hasStripTarget) return

    this.stripTarget.removeEventListener("scroll", this.updateButtons)
    window.removeEventListener("resize", this.updateButtons)
  }

  previous() {
    this.scrollByStep(-1)
  }

  next() {
    this.scrollByStep(1)
  }

  scrollByStep(direction) {
    const step = this.stepSize()
    if (step <= 0) return

    this.stripTarget.scrollBy({
      left: direction * step,
      behavior: this.reducedMotion ? "auto" : "smooth"
    })
  }

  // One "card + gap" step, computed from the first card's width plus the flex
  // gap so the next card lands flush at the strip's left edge.
  stepSize() {
    const firstCard = this.stripTarget.querySelector("[role='listitem']")
    if (!firstCard) return 0

    const gap = parseFloat(getComputedStyle(this.stripTarget).columnGap) || 0
    return firstCard.clientWidth + gap
  }

  updateButtons = () => {
    if (!this.hasStripTarget) return

    const strip = this.stripTarget
    const maxScroll = strip.scrollWidth - strip.clientWidth
    const atStart = strip.scrollLeft <= 1
    const atEnd = strip.scrollLeft >= maxScroll - 1

    if (this.hasPrevButtonTarget) {
      this.prevButtonTarget.disabled = atStart
      this.prevButtonTarget.setAttribute("aria-disabled", String(atStart))
    }
    if (this.hasNextButtonTarget) {
      this.nextButtonTarget.disabled = atEnd
      this.nextButtonTarget.setAttribute("aria-disabled", String(atEnd))
    }
  }
}