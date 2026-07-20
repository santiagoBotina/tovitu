import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  connect() {
    this.timer = setTimeout(() => this.hide(), 5000)
  }

  disconnect() {
    clearTimeout(this.timer)
  }

  hide() {
    this.element.classList.add(
      "opacity-0", "-translate-y-2",
      "transition-all", "duration-300", "ease-out"
    )
    setTimeout(() => this.element.remove(), 300)
  }
}
