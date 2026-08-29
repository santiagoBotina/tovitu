import { Controller } from "@hotwired/stimulus"

// Loading state for the natural-language search form on the browse page.
//
// The form performs a plain GET navigation, so there is no Turbo request to
// hook into. On submit we disable the button, swap its label for the
// localized "loading" copy, and reveal an inline spinner so the user knows
// the search is being processed. The form and button are marked aria-busy
// while the navigation is in flight.
export default class extends Controller {
  static targets = ["submit", "label", "spinner"]
  static values = { loadingLabel: String }

  submit(event) {
    const button = this.submitTarget
    button.disabled = true
    button.setAttribute("aria-busy", "true")
    this.element.setAttribute("aria-busy", "true")
    if (this.hasLabelTarget && this.loadingLabelValue) {
      this.labelTarget.textContent = this.loadingLabelValue
    }
    if (this.hasSpinnerTarget) {
      this.spinnerTarget.classList.remove("hidden")
    }
  }
}