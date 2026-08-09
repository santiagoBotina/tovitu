import { Controller } from "@hotwired/stimulus"

// One-time, best-effort client → server sync: after a visitor creates an
// account, offers to move localStorage interests into real SavedPet records.
// Soft prompt — dismissible, skippable, never blocks.
const INTERESTS_KEY = "tovitu:interests"

export default class extends Controller {
  static targets = ["banner", "idsInput", "count"]
  static values = { skipKey: String, one: String, other: String }

  connect() {
    if (this.skipKeyValue && sessionStorage.getItem(this.skipKeyValue)) return
    const ids = this.readInterests()
    if (!ids.length) return
    this.ids = ids
    if (this.hasIdsInputTarget) this.idsInputTarget.value = ids.join(",")
    if (this.hasCountTarget) {
      const template = ids.length === 1 ? this.oneValue : this.otherValue
      this.countTarget.textContent = (template || "").replace("%{count}", ids.length)
    }
    if (this.hasBannerTarget) this.bannerTarget.classList.remove("hidden")

    // Clear the local copy only AFTER the server confirms the import, so a
    // failed request never destroys the visitor's saved interests.
    const form = this.element.querySelector("form")
    if (form) {
      form.addEventListener("turbo:submit-end", (event) => {
        if (event.detail.success) {
          try {
            localStorage.removeItem(INTERESTS_KEY)
          } catch {
            // ignore
          }
        }
      })
    }
  }

  dismiss(event) {
    event.preventDefault()
    if (this.hasBannerTarget) this.bannerTarget.classList.add("hidden")
    try {
      sessionStorage.setItem(this.skipKeyValue, "1")
    } catch {
      // ignore
    }
  }

  readInterests() {
    try {
      const raw = JSON.parse(localStorage.getItem(INTERESTS_KEY) || "[]")
      if (!Array.isArray(raw)) return []
      return raw.map(Number).filter((n) => Number.isInteger(n) && n > 0)
    } catch {
      return []
    }
  }
}
