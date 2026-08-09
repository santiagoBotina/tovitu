import { Controller } from "@hotwired/stimulus"

// Collapses long summary text with a line clamp and expands it on demand.
// Dependency-free: toggles Tailwind clamp utilities and keeps ARIA state
// (aria-expanded) in sync with the visible state.
export default class extends Controller {
  static targets = ["content", "trigger", "moreLabel", "lessLabel"]
  static values = { expanded: Boolean }

  connect() {
    this.updateTriggerVisibility()
  }

  toggle() {
    this.expandedValue = !this.expandedValue
  }

  expandedValueChanged(expanded) {
    this.triggerTarget.setAttribute("aria-expanded", String(expanded))
    this.contentTarget.classList.toggle("line-clamp-none", expanded)
    this.contentTarget.classList.toggle("line-clamp-3", !expanded)
    if (this.hasMoreLabelTarget) this.moreLabelTarget.hidden = expanded
    if (this.hasLessLabelTarget) this.lessLabelTarget.hidden = !expanded
  }

  // The server renders the expander from a character-length heuristic. In the
  // browser we verify the clamped content actually overflows 3 lines and hide
  // the trigger when it does not, so no dead "Read more" buttons appear.
  updateTriggerVisibility() {
    if (this.expandedValue) return
    this.triggerTarget.hidden = this.contentTarget.scrollHeight <= this.contentTarget.clientHeight
  }
}
