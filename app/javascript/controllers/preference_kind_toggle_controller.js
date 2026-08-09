import { Controller } from "@hotwired/stimulus"

// Keeps the per-kind email section in sync with the global email toggle.
// Global OFF wins (see NotificationPreference#kind_enabled?) — when email is
// off globally the per-kind controls are hidden entirely (their inputs never
// submit), so existing per-kind mutes are preserved for when email is
// re-enabled instead of being wiped to "off".
export default class extends Controller {
  static targets = ["kinds"]

  connect() {
    this.sync()
  }

  sync() {
    const globalEmail = this.element.querySelector('input[name="notification_preference[email]"]')
    const enabled = globalEmail ? globalEmail.checked : true
    this.kindsTarget.classList.toggle("hidden", !enabled)
  }
}
