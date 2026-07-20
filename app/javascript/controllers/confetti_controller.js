import { Controller } from "@hotwired/stimulus"

// One-shot confetti burst controller
// Usage: <div data-controller="confetti" data-action="wizard:complete@document->confetti#fire">
export default class extends Controller {
  static values = {
    count: { type: Number, default: 25 },
    duration: { type: Number, default: 2500 },
    colors: { type: Array, default: [] }
  }

  static DEFAULT_COLORS = [
    "#6C30FF", // primary-500
    "#00C9A7", // secondary-500
    "#FF5DA8", // accent-pink
    "#FFC83D", // accent-yellow
    "#FF7A30", // accent-orange
    "#9163FF", // primary-400
    "#34D399", // secondary-400
    "#FF6B6B", // coral-accent
  ]

  connect() {
    // Guard for reduced motion
    this.reducedMotion = window.matchMedia("(prefers-reduced-motion: reduce)").matches
  }

  fire() {
    if (this.reducedMotion) return

    const container = document.createElement("div")
    container.className = "confetti-container"
    container.setAttribute("aria-hidden", "true")
    document.body.appendChild(container)

    const colors = this.colorsValue.length > 0 ? this.colorsValue : this.constructor.DEFAULT_COLORS
    const isMobile = window.innerWidth < 480
    const pieceCount = isMobile ? Math.min(this.countValue, 15) : this.countValue

    for (let i = 0; i < pieceCount; i++) {
      const piece = document.createElement("div")
      const color = colors[Math.floor(Math.random() * colors.length)]

      const size = Math.random() * 8 + 4
      const left = Math.random() * 100
      const delay = Math.random() * 0.5
      const rotation = Math.random() * 360
      const shape = Math.random() > 0.5 ? "50%" : "2px"

      piece.style.cssText = `
        position: absolute;
        top: -10px;
        left: ${left}%;
        width: ${size}px;
        height: ${size * 1.4}px;
        background: ${color};
        border-radius: ${shape};
        transform: rotate(${rotation}deg);
        animation: confetti-fall ${this.durationValue + Math.random() * 500}ms linear ${delay}s forwards;
        opacity: 0;
      `

      container.appendChild(piece)
    }

    // Auto-cleanup after animation completes
    setTimeout(() => {
      if (container.parentNode) {
        container.parentNode.removeChild(container)
      }
    }, this.durationValue + 1500)
  }
}
