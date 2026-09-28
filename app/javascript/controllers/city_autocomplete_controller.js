import { Controller } from "@hotwired/stimulus"
import { US_CITIES } from "utils/us_cities"

// City autocomplete for the location manual-entry form. As the user types it
// filters a bundled US city list and offers matches; selecting one fills the
// visible city input and auto-fills the region (state) + country fields.
//
// Accessibility: ARIA 1.2 combobox + listbox popup pattern. Arrow keys move
// the active option (aria-activedescendant), Enter selects, Escape closes,
// click-outside closes. The underlying text input stays the source of truth,
// so a manual (unmatched) city is still valid.
export default class extends Controller {
  static targets = ["city", "region", "country", "listbox", "option"]
  static values = {
    open: Boolean,
    minLength: { type: Number, default: 1 },
    maxResults: { type: Number, default: 8 },
    countryValue: { type: String, default: "United States" }
  }

  connect() {
    this.reducedMotion = window.matchMedia("(prefers-reduced-motion: reduce)").matches
    this.activeIndex = -1
    this._options = []
    document.addEventListener("click", this.handleDocumentClick)
    document.addEventListener("keydown", this.handleGlobalKeydown)
  }

  disconnect() {
    document.removeEventListener("click", this.handleDocumentClick)
    document.removeEventListener("keydown", this.handleGlobalKeydown)
  }

  // ─── Filtering ─────────────────────────────────────────────────────────

  filter() {
    const query = this.cityTarget.value.trim().toLowerCase()
    const matches = query.length < this.minLengthValue
      ? []
      : US_CITIES
          .filter((c) => c.city.toLowerCase().startsWith(query) || c.city.toLowerCase().includes(query))
          .slice(0, this.maxResultsValue)

    this.render(matches)

    if (matches.length > 0) {
      this.open()
    } else {
      this.close()
    }
  }

  render(matches) {
    this._options.forEach((opt) => opt.remove())
    this._options = []

    matches.forEach((match) => {
      const option = document.createElement("li")
      option.id = `${this.element.id}-option-${this._options.length}`
      option.setAttribute("role", "option")
      option.setAttribute("data-city-autocomplete-target", "option")
      option.dataset.value = match.city
      option.dataset.state = match.state
      option.textContent = `${match.city}, ${match.state}`
      option.className =
        "px-4 py-2.5 text-sm cursor-pointer text-neutral-700 hover:bg-primary-50 transition-colors"
      option.addEventListener("mousedown", (event) => {
        event.preventDefault()
        this.select(match)
      })
      this.listboxTarget.appendChild(option)
      this._options.push(option)
    })
  }

  // ─── Selection ─────────────────────────────────────────────────────────

  select(match) {
    this.cityTarget.value = match.city
    if (this.hasRegionTarget) this.regionTarget.value = match.state
    if (this.hasCountryTarget && !this.countryTarget.value.trim()) {
      this.countryTarget.value = this.countryValueValue
    }
    this.close()
    this.dispatch("city:selected", { detail: match, bubbles: true })
  }

  // ─── Open / close ──────────────────────────────────────────────────────

  open() {
    this.listboxTarget.classList.remove("hidden")
    if (!this.reducedMotion) {
      this.listboxTarget.classList.remove("city-menu-enter")
      void this.listboxTarget.offsetWidth
      this.listboxTarget.classList.add("city-menu-enter")
    }
    this.cityTarget.setAttribute("aria-expanded", "true")
    this.activeIndex = -1
    this.openValue = true
  }

  close() {
    if (!this.openValue) return
    this.listboxTarget.classList.add("hidden")
    this.listboxTarget.classList.remove("city-menu-enter")
    this.cityTarget.setAttribute("aria-expanded", "false")
    this.cityTarget.removeAttribute("aria-activedescendant")
    this.openValue = false
  }

  // ─── Keyboard support ──────────────────────────────────────────────────

  onKeydown(event) {
    switch (event.key) {
      case "ArrowDown":
        if (this.openValue) {
          event.preventDefault()
          this.move(1)
        }
        break
      case "ArrowUp":
        if (this.openValue) {
          event.preventDefault()
          this.move(-1)
        }
        break
      case "Enter":
        if (this.openValue && this.activeIndex >= 0) {
          event.preventDefault()
          this.commitActive()
        }
        break
      case "Escape":
        if (this.openValue) {
          event.preventDefault()
          this.close()
          this.cityTarget.focus()
        }
        break
      case "Tab":
        if (this.openValue) this.close()
        break
    }
  }

  move(delta) {
    const count = this._options.length
    if (count === 0) return
    this.activeIndex = (this.activeIndex + delta + count) % count
    this._options.forEach((opt, i) => {
      const isActive = i === this.activeIndex
      opt.classList.toggle("bg-primary-50", isActive)
      opt.classList.toggle("text-primary-700", isActive)
    })
    this.cityTarget.setAttribute("aria-activedescendant", this._options[this.activeIndex].id)
  }

  commitActive() {
    const option = this._options[this.activeIndex]
    if (!option) return
    this.select({ city: option.dataset.value, state: option.dataset.state })
  }

  // ─── Click outside ─────────────────────────────────────────────────────

  handleDocumentClick = (event) => {
    if (this.openValue && !this.element.contains(event.target)) this.close()
  }

  // Close on Escape even when focus has left the input but the popup is open.
  handleGlobalKeydown = (event) => {
    if (event.key === "Escape" && this.openValue) this.close()
  }
}