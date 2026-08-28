import { Controller } from "@hotwired/stimulus"

// Navbar saved-pets counter badge. Keeps the count in sync with optimistic
// save/remove actions by listening for tovitu:favorites-changed events
// (dispatched by favorite-toggle on every optimistic change and on failure
// revert, so the badge always converges with the visual state).
export default class extends Controller {
  static values = { count: Number }

  connect() {
    this.render()
    this._onChange = (event) => {
      const delta = event.detail?.delta
      if (typeof delta !== "number") return
      this.countValue = Math.max(0, this.countValue + delta)
      this.render()
    }
    document.addEventListener("tovitu:favorites-changed", this._onChange)
  }

  disconnect() {
    document.removeEventListener("tovitu:favorites-changed", this._onChange)
  }

  render() {
    this.element.textContent = this.countValue
    this.element.classList.toggle("hidden", this.countValue <= 0)
  }
}