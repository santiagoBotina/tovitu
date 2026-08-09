import { Controller } from "@hotwired/stimulus"

// Signed-out navbar heart. Forwards the click to the body-level
// interest-prompt dialog by dispatching the app-wide "tovitu:interest-prompt"
// event — the same event used by exploration memory and the saved-pet nudge,
// so the dialog itself lives once, outside the navbar's stacking context.
export default class extends Controller {
  trigger() {
    document.dispatchEvent(new CustomEvent("tovitu:interest-prompt"))
  }
}
