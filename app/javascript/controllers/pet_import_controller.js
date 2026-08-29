import { Controller } from "@hotwired/stimulus"

// Pet-import page status polling. While a background batch import is pending,
// polls the per-import status endpoint and applies the returned turbo_stream
// (which swaps the progress notice and, once the import lands, the summary).
// The notice element carries data-pet-import-status:
//   pending   → keep polling
//   failed    → stop (wait for a new import)
//   completed → stop
// Polling caps out after maxTicks so a never-finishing import doesn't poll forever.
export default class extends Controller {
  static values = {
    statusUrl: String,
    interval: { type: Number, default: 2000 },
    maxTicks: { type: Number, default: 90 },
  }

  connect() {
    this.ticks = 0
    this.timer = setInterval(() => this.tick(), this.intervalValue)
  }

  disconnect() {
    clearInterval(this.timer)
  }

  tick() {
    const notice = document.getElementById("pet-import-notice")
    const status = notice?.dataset.petImportStatus
    if (status === "completed" || status === "failed") {
      clearInterval(this.timer)
      return
    }
    if (status === "pending") {
      this.ticks += 1
      if (this.ticks > this.maxTicksValue) {
        clearInterval(this.timer)
        return
      }
      this.check()
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