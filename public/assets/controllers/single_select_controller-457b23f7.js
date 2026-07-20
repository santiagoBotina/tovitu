import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["option", "container"]
  static values = { selected: String }

  connect() {
    this.reducedMotion = window.matchMedia("(prefers-reduced-motion: reduce)").matches
    if (this.selectedValue) {
      this.setValue(this.selectedValue)
    }
  }

  select(event) {
    const selected = event.currentTarget

    this.optionTargets.forEach(opt => {
      opt.classList.remove("bg-primary-50", "border-primary-400", "text-primary-700")
      opt.classList.add("bg-white", "border-neutral-200", "text-neutral-600", "hover:border-primary-300", "hover:text-primary-600", "hover:bg-primary-50/50")
    })

    selected.classList.remove("bg-white", "border-neutral-200", "text-neutral-600", "hover:border-primary-300", "hover:text-primary-600", "hover:bg-primary-50/50")
    selected.classList.add("bg-primary-50", "border-primary-400", "text-primary-700")

    // Selection pulse animation
    if (!this.reducedMotion) {
      selected.classList.add("select-pulse")
      setTimeout(() => selected.classList.remove("select-pulse"), 300)
    }

    this.showPetPop(event)

    // Dispatch question:completed event for the parent onboarding controller
    this.dispatch("question:completed", {
      detail: { value: this.getValue() },
      bubbles: true
    })
  }

  getValue() {
    const selected = this.optionTargets.find(opt =>
      opt.classList.contains("bg-primary-50")
    )
    return selected ? selected.dataset.value : ""
  }

  setValue(value) {
    if (!value) return
    this.optionTargets.forEach(opt => {
      if (opt.dataset.value === value) {
        opt.classList.remove("bg-white", "border-neutral-200", "text-neutral-600", "hover:border-primary-300", "hover:text-primary-600", "hover:bg-primary-50/50")
        opt.classList.add("bg-primary-50", "border-primary-400", "text-primary-700")
      }
    })
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
