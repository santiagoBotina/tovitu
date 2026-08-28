import { Controller } from "@hotwired/stimulus"

// Auto-import of localStorage interests after authentication.
//
// Rendered once at body level for signed-in individuals. On connect it checks
// for locally saved pet ids (the signed-out "paw it" list). If any exist, it
// POSTs them to the import endpoint, which persists them server-side in a
// FavoritesImport record and imports them in the background. The user is told
// immediately via a toast and can keep browsing.
//
// Safety: the local copy is cleared only AFTER the server accepts the import
// (the ids are then persisted server-side), so a failed request never destroys
// the visitor's saved interests — the next page load retries automatically.
const INTERESTS_KEY = "tovitu:interests"

export default class extends Controller {
  static values = { importUrl: String }

  connect() {
    const ids = this.readInterests()
    if (!ids.length) return
    this.importInterests(ids)
  }

  async importInterests(ids) {
    const formData = new FormData()
    formData.append("pet_ids", ids.join(","))

    try {
      const response = await fetch(this.importUrlValue, {
        method: "POST",
        headers: {
          "Accept": "text/vnd.turbo-stream.html",
          "X-CSRF-Token": this.csrfToken(),
        },
        body: formData,
        credentials: "same-origin",
      })
      if (!response.ok) throw new Error("import failed")

      const html = await response.text()
      if (html.trim()) Turbo.renderStreamMessage(html)
      this.clearInterests()
    } catch {
      // Keep the local copy; the next page load retries automatically.
    }
  }

  csrfToken() {
    const meta = document.querySelector('meta[name="csrf-token"]')
    return meta ? meta.content : ""
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

  clearInterests() {
    try {
      localStorage.removeItem(INTERESTS_KEY)
    } catch {
      // ignore
    }
  }
}