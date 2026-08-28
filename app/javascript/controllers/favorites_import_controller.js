import { Controller } from "@hotwired/stimulus"

// Saved-pets page import status polling.
//
// While a background favorites import is pending, polls import_status and
// applies the returned turbo_stream (which swaps the notice, and once the
// import lands, the list + a summary toast). The notice element carries
// data-favorites-import-status:
//   pending   → keep polling
//   failed    → wait (the retry form flips it back to pending)
//   completed → stop polling
//
// When no notice exists yet (the auto-import POST from the layout is still in
// flight after authentication), signed-in users keep polling until the import
// appears so the "importing" notice is never missed.
export default class extends Controller {
  static values = {
    statusUrl: String,
    signedIn: Boolean,
    interval: { type: Number, default: 2000 },
    maxNoNoticeTicks: { type: Number, default: 10 },
  }

  connect() {
    this.noNoticeTicks = 0
    this.timer = setInterval(() => this.tick(), this.intervalValue)
  }

  disconnect() {
    clearInterval(this.timer)
  }

  tick() {
    const notice = document.getElementById("favorites-import-notice")
    const status = notice?.dataset.favoritesImportStatus
    if (status === "completed") {
      clearInterval(this.timer)
      return
    }
    if (status === "failed") return
    if (status === "pending") {
      this.noNoticeTicks = 0
      this.check()
      return
    }
    // No notice yet — only poll while local interests exist (the auto-import
    // POST from the layout is still starting up), and stop after a cap so a
    // persistently failing auto-import doesn't poll forever.
    if (this.signedInValue && this.hasLocalInterests()) {
      this.noNoticeTicks += 1
      if (this.noNoticeTicks > this.maxNoNoticeTicksValue) {
        clearInterval(this.timer)
        return
      }
      this.check()
    }
  }

  hasLocalInterests() {
    try {
      const raw = JSON.parse(localStorage.getItem("tovitu:interests") || "[]")
      return Array.isArray(raw) && raw.length > 0
    } catch {
      return false
    }
  }

  async check() {
    try {
      const response = await fetch(this.statusUrlValue, {
        headers: { "Accept": "text/vnd.turbo-stream.html" },
        credentials: "same-origin",
      })
      if (!response.ok) return
      const html = await response.text()
      if (html.trim()) Turbo.renderStreamMessage(html)
    } catch {
      // Network hiccup — keep polling; the next tick retries.
    }
  }
}