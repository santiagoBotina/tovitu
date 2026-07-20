import { Controller } from "@hotwired/stimulus"

// Manages the first-time welcome overlay on the shelter dashboard
// Dismisses and persists dismissal state via sessionStorage
export default class extends Controller {
  static values = { dismissed: Boolean }

  connect() {
    // Check session storage for dismissal
    try {
      const dismissed = sessionStorage.getItem("tovitu_welcome_dismissed")
      if (dismissed === "true" || this.dismissedValue) {
        this.element.remove()
      }
    } catch (e) {
      // sessionStorage not available
    }
  }

  dismiss() {
    this.element.classList.add("opacity-0")
    setTimeout(() => {
      this.element.remove()
    }, 300)

    try {
      sessionStorage.setItem("tovitu_welcome_dismissed", "true")
    } catch (e) {
      // sessionStorage not available
    }
  }

  stopPropagation(event) {
    event.stopPropagation()
  }
}
