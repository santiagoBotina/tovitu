import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static values = {
    threshold: { type: Number, default: 0.15 },
    stagger: { type: Number, default: 0 }
  }

  connect() {
    this.element.classList.add("reveal-ready")
    this.observer = new IntersectionObserver(
      (entries) => this.reveal(entries),
      { threshold: this.thresholdValue }
    )
    this.observer.observe(this.element)
  }

  reveal(entries) {
    entries.forEach(entry => {
      if (!entry.isIntersecting) return

      if (this.hasStaggerValue && this.staggerValue > 0) {
        const items = this.element.querySelectorAll("[data-reveal-item]")
        items.forEach((item, i) => {
          item.style.transitionDelay = `${i * this.staggerValue}ms`
          item.classList.add("is-visible")
        })
      } else {
        this.element.classList.add("is-visible")
      }

      this.observer.unobserve(this.element)
    })
  }

  disconnect() {
    if (this.observer) this.observer.disconnect()
  }
}
