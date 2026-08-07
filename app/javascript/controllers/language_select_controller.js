import { Controller } from "@hotwired/stimulus"

// Custom, on-brand language selector (listbox popup pattern).
//
// The surrounding form always keeps a native <select name="user[locale]"> as
// the no-JS fallback and source of truth. When this controller connects it:
//   1. hides the native select + save button,
//   2. reveals the custom combobox control,
//   3. auto-saves the locale by submitting the surrounding profile form
//      (PATCH profile_path) as soon as an option is chosen.
//
// Accessibility: follows the ARIA 1.2 combobox + listbox popup pattern.
// Focus stays on the trigger button; arrow keys move the active option via
// aria-activedescendant; Enter selects; Escape closes; click-outside closes.
export default class extends Controller {
  static targets = ["native", "control", "trigger", "triggerLabel", "menu", "option", "submit"]
  static values = { open: Boolean }

  connect() {
    this.reducedMotion = window.matchMedia("(prefers-reduced-motion: reduce)").matches
    this.activeIndex = 0

    this.upgrade()
    this.syncSelected()

    document.addEventListener("click", this.handleDocumentClick)
  }

  disconnect() {
    document.removeEventListener("click", this.handleDocumentClick)
  }

  // ─── Progressive enhancement ───────────────────────────────────────────

  upgrade() {
    this.nativeTarget.hidden = true
    this.submitTarget.hidden = true
    this.controlTarget.classList.remove("hidden")
  }

  // ─── State sync ─────────────────────────────────────────────────────────

  syncSelected() {
    const selected = this.nativeTarget.value

    this.optionTargets.forEach((option, index) => {
      const isSelected = option.dataset.value === selected
      // Clear any transient arrow-key "active" state before applying selection.
      option.classList.remove("bg-primary-50", "text-primary-700")
      option.setAttribute("aria-selected", isSelected ? "true" : "false")
      option.classList.toggle("bg-primary-500", isSelected)
      option.classList.toggle("text-white", isSelected)
      option.classList.toggle("text-neutral-700", !isSelected)
      option.classList.toggle("hover:bg-primary-50", !isSelected)
      option.querySelector("[data-language-select-target='check']")?.classList.toggle("hidden", !isSelected)
      if (isSelected) this.activeIndex = index
    })

    this.triggerLabelTarget.textContent = this.labelFor(selected)
  }

  labelFor(value) {
    const option = this.optionTargets.find((opt) => opt.dataset.value === value)
    return option ? option.textContent.trim() : this.triggerLabelTarget.textContent
  }

  // ─── Open / close ───────────────────────────────────────────────────────

  toggle(event) {
    event.preventDefault()
    if (this.openValue) {
      this.close()
    } else {
      this.open()
    }
  }

  open() {
    this.menuTarget.classList.remove("hidden")
    if (!this.reducedMotion) {
      this.menuTarget.classList.remove("language-menu-enter")
      // Force a reflow so the animation plays when reopening.
      void this.menuTarget.offsetWidth
      this.menuTarget.classList.add("language-menu-enter")
    }
    this.triggerTarget.setAttribute("aria-expanded", "true")
    this.triggerTarget.setAttribute("aria-activedescendant", this.activeOption().id)
    this.openValue = true
  }

  close({ focusTrigger = false } = {}) {
    if (!this.openValue && this.menuTarget.classList.contains("hidden")) return
    this.menuTarget.classList.add("hidden")
    this.menuTarget.classList.remove("language-menu-enter")
    this.triggerTarget.setAttribute("aria-expanded", "false")
    this.triggerTarget.removeAttribute("aria-activedescendant")
    this.openValue = false
    if (focusTrigger) this.triggerTarget.focus()
  }

  // ─── Keyboard support ───────────────────────────────────────────────────

  onKeydown(event) {
    switch (event.key) {
      case "ArrowDown":
        event.preventDefault()
        if (!this.openValue) this.open()
        this.move(1)
        break
      case "ArrowUp":
        event.preventDefault()
        if (!this.openValue) this.open()
        this.move(-1)
        break
      case "Home":
        if (this.openValue) {
          event.preventDefault()
          this.moveTo(0)
        }
        break
      case "End":
        if (this.openValue) {
          event.preventDefault()
          this.moveTo(this.optionTargets.length - 1)
        }
        break
      case "Enter":
        if (this.openValue) {
          event.preventDefault()
          this.selectOption(this.activeOption())
        }
        break
      case "Escape":
        if (this.openValue) {
          event.preventDefault()
          this.close({ focusTrigger: true })
        }
        break
      case "Tab":
        if (this.openValue) this.close()
        break
    }
  }

  move(delta) {
    const count = this.optionTargets.length
    if (count === 0) return
    this.moveTo((this.activeIndex + delta + count) % count)
  }

  moveTo(index) {
    this.activeIndex = index
    const selected = this.nativeTarget.value

    this.optionTargets.forEach((option, i) => {
      const isActive = i === this.activeIndex
      const isSelected = option.dataset.value === selected
      option.classList.toggle("bg-primary-50", isActive && !isSelected)
      option.classList.toggle("text-primary-700", isActive && !isSelected)
    })

    this.triggerTarget.setAttribute("aria-activedescendant", this.activeOption().id)
  }

  activeOption() {
    return this.optionTargets[this.activeIndex]
  }

  // ─── Selection ──────────────────────────────────────────────────────────

  select(event) {
    this.selectOption(event.currentTarget)
  }

  selectOption(option) {
    if (!option) return
    const value = option.dataset.value
    const changed = this.nativeTarget.value !== value

    this.nativeTarget.value = value
    this.syncSelected()
    this.close()

    if (changed) {
      const form = this.element.closest("form")
      if (form) form.requestSubmit()
    }
  }

  // ─── Click outside ──────────────────────────────────────────────────────

  handleDocumentClick = (event) => {
    if (!this.openValue) return
    if (this.element.contains(event.target)) return
    this.close()
  }
}
