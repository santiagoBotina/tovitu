import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["menu"]

  connect() {
    this.open = false
    this.boundOutsideClick = this._outsideClick.bind(this)
    this.boundKeydown = this._onKeydown.bind(this)
    document.addEventListener("keydown", this.boundKeydown)
    this._cleanupNavigation = this._closeOnNavigate()
  }

  disconnect() {
    document.removeEventListener("keydown", this.boundKeydown)
    document.removeEventListener("click", this.boundOutsideClick)
    this._cleanupNavigation?.()
  }

  toggle(event) {
    event.stopPropagation()
    if (this.open) {
      this.hide()
    } else {
      this.show()
    }
  }

  show() {
    if (this.open) return
    this.open = true
    this.menuTarget.classList.remove("hidden", "opacity-0", "scale-95")
    this.menuTarget.classList.add("opacity-100", "scale-100")
    this._updateAriaExpanded()

    // Register outside click on next frame to avoid immediate re-close
    requestAnimationFrame(() => {
      document.addEventListener("click", this.boundOutsideClick)
    })
  }

  hide() {
    if (!this.open) return
    this.open = false
    this.menuTarget.classList.add("hidden", "opacity-0", "scale-95")
    this.menuTarget.classList.remove("opacity-100", "scale-100")
    this._updateAriaExpanded()
    document.removeEventListener("click", this.boundOutsideClick)
  }

  _outsideClick(event) {
    if (!this.element.contains(event.target)) {
      this.hide()
    }
  }

  _onKeydown(event) {
    if (event.key === "Escape" && this.open) {
      this.hide()
      this.element.querySelector("button")?.focus()
    }
  }

  _updateAriaExpanded() {
    const trigger = this.element.querySelector("button")
    if (trigger) {
      trigger.setAttribute("aria-expanded", String(this.open))
    }
  }

  _closeOnNavigate() {
    const handler = () => this.hide()
    document.addEventListener("turbo:before-render", handler)
    return () => document.removeEventListener("turbo:before-render", handler)
  }
}
