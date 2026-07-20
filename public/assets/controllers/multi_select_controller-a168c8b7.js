import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["chip", "selectedCount", "errorMessage", "container"]
  static classes = ["selected"]
  static values = { selected: Array }

  connect() {
    this.reducedMotion = window.matchMedia("(prefers-reduced-motion: reduce)").matches
    if (this.selectedValue && this.selectedValue.length > 0) {
      this.setValue(this.selectedValue)
    }
    this.updateCount()
  }

  toggle(event) {
    const chip = event.currentTarget
    const isSelected = chip.classList.contains("bg-primary-100")

    if (isSelected) {
      chip.classList.remove("bg-primary-100", "border-primary-400", "text-primary-700")
      chip.classList.add("bg-white", "border-neutral-200", "text-neutral-600")
    } else {
      chip.classList.remove("bg-white", "border-neutral-200", "text-neutral-600")
      chip.classList.add("bg-primary-100", "border-primary-400", "text-primary-700")

      // Selection pulse animation
      if (!this.reducedMotion) {
        chip.classList.add("select-pulse")
        setTimeout(() => chip.classList.remove("select-pulse"), 300)
      }

      this.showPetPop(event)
    }

    if (this.hasErrorMessageTarget) {
      this.errorMessageTarget.classList.add("hidden")
    }

    this.updateCount()

    // Dispatch question:completed event
    this.dispatch("question:completed", {
      detail: { value: this.getValue(), count: this.getValue().length },
      bubbles: true
    })
  }

  getValue() {
    return Array.from(this.chipTargets)
      .filter(chip => chip.classList.contains("bg-primary-100"))
      .map(chip => chip.dataset.value)
  }

  setValue(values) {
    if (!Array.isArray(values)) values = [values]
    this.chipTargets.forEach(chip => {
      if (values.includes(chip.dataset.value)) {
        chip.classList.remove("bg-white", "border-neutral-200", "text-neutral-600")
        chip.classList.add("bg-primary-100", "border-primary-400", "text-primary-700")
      }
    })
    this.updateCount()
  }

  updateCount() {
    const count = this.getValue().length
    if (this.hasSelectedCountTarget) {
      if (count > 0) {
        this.selectedCountTarget.textContent = `${count} selected`
      } else {
        this.selectedCountTarget.textContent = ""
      }
    }
  }

  showPetPop(event) {
    const rect = event.currentTarget.getBoundingClientRect()
    const el = document.createElement("span")
    el.textContent = "\u{1F43E}"
    el.className = "pet-pop-animation"
    el.style.left = `${rect.left + rect.width / 2}px`
    el.style.top = `${rect.top}px`
    document.body.appendChild(el)
    setTimeout(() => el.remove(), 600)
  }
}
