import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static values = {
    threshold: { type: Number, default: 0.15 },
    stagger: { type: Number, default: 0 }
  }

  connect() {
    if (window.matchMedia("(prefers-reduced-motion: reduce)").matches) return

    if (this.element.getBoundingClientRect().top < window.innerHeight) return

    const items = this.element.querySelectorAll("[data-reveal-item]")
    items.forEach(item => {
      item.style.opacity = "0"
      item.style.transform = "translateY(20px)"
    })

    this.observer = new IntersectionObserver(
      (entries) => this.onIntersect(entries),
      { threshold: this.thresholdValue }
    )
    this.observer.observe(this.element)
  }

  onIntersect(entries) {
    entries.forEach(entry => {
      if (!entry.isIntersecting) return
      this.revealNow()
      this.observer.unobserve(this.element)
    })
  }

  revealNow() {
    const items = this.element.querySelectorAll("[data-reveal-item]")
    if (items.length === 0) return

    items.forEach(item => {
      item.style.opacity = "0"
      item.style.transform = "translateY(20px)"
    })

    requestAnimationFrame(() => {
      items.forEach((item, i) => {
        const delay = this.hasStaggerValue && this.staggerValue > 0
          ? `${i * this.staggerValue}ms`
          : "0ms"
        item.style.transition = [
          "opacity 600ms cubic-bezier(0.25, 1, 0.5, 1)",
          "transform 600ms cubic-bezier(0.25, 1, 0.5, 1)"
        ].join(",")
        item.style.transitionDelay = delay
        item.style.opacity = "1"
        item.style.transform = "translateY(0)"
      })
    })
  }

  disconnect() {
    if (this.observer) this.observer.disconnect()
  }
}
