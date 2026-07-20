import { Controller } from "@hotwired/stimulus"

// Manages the first-time welcome overlay on the shelter dashboard
// Starts hidden, shows if not previously dismissed (stored in sessionStorage)
// Dismisses and persists dismissal state via sessionStorage
export default class extends Controller {
  connect() {
    // Check session storage for dismissal before showing
    try {
      const dismissed = sessionStorage.getItem("tovitu_welcome_dismissed")
      if (dismissed === "true") {
        this.element.remove()
        return
      }
    } catch (e) {
      // sessionStorage not available — show overlay anyway
    }

    // Show overlay with fade-in after checking dismissal state
    this.element.classList.remove("hidden")
    requestAnimationFrame(() => {
      this.element.classList.remove("opacity-0")
    })
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
