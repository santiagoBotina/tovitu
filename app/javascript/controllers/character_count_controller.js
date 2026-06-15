import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["input", "counter", "count"]
  static values = { maxLength: Number }

  connect() {
    this.update()
  }

  update() {
    const max = this.maxLengthValue || 200
    const current = this.inputTarget.value.length

    if (this.hasCountTarget) {
      this.countTarget.textContent = current
    }

    if (this.hasCounterTarget) {
      this.counterTarget.textContent = `${current}/${max}`
    }

    this.inputTarget.classList.remove("border-warning", "border-danger", "text-danger")

    if (current >= max) {
      this.inputTarget.classList.add("border-danger", "text-danger")
    } else if (current >= max * 0.8) {
      this.inputTarget.classList.add("border-warning")
    }
  }
}
