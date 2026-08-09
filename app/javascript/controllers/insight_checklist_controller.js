import { Controller } from "@hotwired/stimulus"

// Lightweight, non-persistent checklist for the adopter insight check-ins.
// Lets reviewers track which verification questions they've confirmed with
// the applicant during the current review session. Nothing is saved.
export default class extends Controller {
  static targets = ["row"]

  toggle(event) {
    const row = event.currentTarget.closest("[data-insight-checklist-target='row']")
    if (!row) return
    row.classList.toggle("is-checked", event.currentTarget.checked)
  }
}
