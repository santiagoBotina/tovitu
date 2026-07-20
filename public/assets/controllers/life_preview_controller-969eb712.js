import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static values = { name: String, url: String }
  static targets = ["message"]

  messages = [
    "Imagining a life with %{name}...",
    "Matching your profile with %{name}...",
    "Preparing a week-by-week plan...",
    "Building a daily routine for %{name}...",
    "Gathering preparation tips...",
    "Almost there..."
  ]

  connect() {
    this.messageIndex = 0
    this.pollCount = 0
    this.maxPolls = 30
    this.fallbackShown = false
    this.cycleTimeout = null

    this.updateMessage()

    this.messageInterval = setInterval(() => this.cycleMessage(), 3500)
    this.pollInterval = setInterval(() => this.poll(), 4000)
  }

  disconnect() {
    clearInterval(this.messageInterval)
    clearInterval(this.pollInterval)
    if (this.cycleTimeout) {
      clearTimeout(this.cycleTimeout)
      this.cycleTimeout = null
    }
  }

  cycleMessage() {
    if (this.hasMessageTarget) {
      this.messageTarget.classList.add("opacity-0")
    }

    this.cycleTimeout = setTimeout(() => {
      if (!this.hasMessageTarget) return

      this.messageIndex = (this.messageIndex + 1) % this.messages.length
      this.updateMessage()

      this.messageTarget.classList.remove("opacity-0")
    }, 300)
  }

  updateMessage() {
    if (!this.hasMessageTarget) return
    const msg = this.messages[this.messageIndex].replace("%{name}", this.nameValue)
    this.messageTarget.textContent = msg
  }

  poll() {
    const src = this.hasUrlValue ? this.urlValue : null
    if (!src) return

    this.pollCount++
    if (this.pollCount > this.maxPolls) {
      this.handlePollTimeout()
      return
    }

    const separator = src.includes("?") ? "&" : "?"

    fetch(`${src}${separator}_poll=${Date.now()}`)
      .then(r => r.ok ? r.text() : Promise.reject())
      .then(html => {
        if (!html || html.includes("life-preview-loading")) return

        clearInterval(this.messageInterval)
        clearInterval(this.pollInterval)
        if (this.cycleTimeout) {
          clearTimeout(this.cycleTimeout)
          this.cycleTimeout = null
        }

        const frame = document.getElementById("life_preview")
        if (!frame) return

        frame.setAttribute("src", `${src}${separator}_t=${Date.now()}`)
      })
      .catch(() => {})
  }

  handlePollTimeout() {
    if (this.fallbackShown) return
    this.fallbackShown = true

    clearInterval(this.messageInterval)
    clearInterval(this.pollInterval)
    if (this.cycleTimeout) {
      clearTimeout(this.cycleTimeout)
      this.cycleTimeout = null
    }

    if (this.hasMessageTarget) {
      this.messageTarget.textContent = "Taking longer than expected — refresh the page to try again."
      this.messageTarget.classList.remove("opacity-0")
    }
  }
}
