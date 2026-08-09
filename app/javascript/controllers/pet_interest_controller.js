import { Controller } from "@hotwired/stimulus"

// Client-side "paw it" bookmark for signed-out visitors.
// Stores pet ids in localStorage["tovitu:interests"] (deduped, capped).
// Signed-in users keep using the server-backed save button.
const INTERESTS_KEY = "tovitu:interests"
const MAX_INTERESTS = 20

export default class extends Controller {
  static targets = ["icon", "label"]
  static values = {
    id: Number,
    saveLabel: String,
    unsaveLabel: String,
  }

  connect() {
    this.interests = this.read()
    this.render()
    // Keep multiple controls for the same pet in sync (e.g. the heart on the
    // profile hero + the labeled sidebar button). Each instance listens for
    // interest changes that concern its own pet.
    this.sync = this.sync.bind(this)
    document.addEventListener("tovitu:interest-changed", this.sync)
  }

  disconnect() {
    document.removeEventListener("tovitu:interest-changed", this.sync)
  }

  sync(event) {
    if (event.detail.petId === this.idValue) {
      // Re-read from storage: this instance's in-memory copy is stale and the
      // change may have come from a sibling control.
      this.interests = this.read()
      this.render()
    }
  }

  toggle(event) {
    event.preventDefault()
    event.stopPropagation()

    this.interests = this.read()
    const id = this.idValue
    const index = this.interests.indexOf(id)
    let action = "saved"

    if (index >= 0) {
      this.interests.splice(index, 1)
      action = "unsaved"
    } else {
      if (this.interests.length >= MAX_INTERESTS) this.interests.shift()
      this.interests.push(id)
    }

    this.write(this.interests)
    this.render()

    document.dispatchEvent(new CustomEvent("tovitu:interest-changed", {
      detail: { count: this.interests.length, petId: id, action },
    }))

    // Friendly conversion nudge on the 2nd+ saved pet. Seen once per
    // session so it never hard-walls or nags on every tap.
    if (action === "saved" && this.interests.length >= 2) {
      if (!sessionStorage.getItem("tovitu:interest_prompt_seen")) {
        sessionStorage.setItem("tovitu:interest_prompt_seen", "1")
        document.dispatchEvent(new CustomEvent("tovitu:interest-prompt"))
      }
    }
  }

  read() {
    try {
      const raw = JSON.parse(localStorage.getItem(INTERESTS_KEY) || "[]")
      if (!Array.isArray(raw)) return []
      return raw.map(Number).filter((n) => Number.isInteger(n) && n > 0)
    } catch {
      return []
    }
  }

  write(ids) {
    try {
      localStorage.setItem(INTERESTS_KEY, JSON.stringify(ids))
    } catch {
      // Storage unavailable (private mode / quota) — interest stays ephemeral.
    }
  }

  render() {
    if (!this.hasIconTarget) return
    const saved = this.interests.includes(this.idValue)
    const icon = this.iconTarget
    icon.classList.toggle("fill-accent-pink", saved)
    icon.classList.toggle("text-accent-pink", saved)
    icon.classList.toggle("fill-transparent", !saved)
    icon.classList.toggle("text-neutral-400", !saved)
    icon.classList.toggle("heart-saved", saved)
    if (this.hasLabelTarget) {
      this.labelTarget.textContent = saved ? this.unsaveLabelValue : this.saveLabelValue
    }
    this.element.setAttribute("aria-label", saved ? this.unsaveLabelValue : this.saveLabelValue)
    this.element.setAttribute("aria-pressed", String(saved))
  }
}
