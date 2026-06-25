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
    this.updateMessage()
    this.messageInterval = setInterval(() => this.cycleMessage(), 3500)
    this.pollInterval = setInterval(() => this.poll(), 4000)
  }

  disconnect() {
    clearInterval(this.messageInterval)
    clearInterval(this.pollInterval)
  }

  cycleMessage() {
    this.messageIndex = (this.messageIndex + 1) % this.messages.length
    this.updateMessage()
  }

  updateMessage() {
    if (!this.hasMessageTarget) return
    const msg = this.messages[this.messageIndex].replace("%{name}", this.nameValue)
    this.messageTarget.textContent = msg
  }

  poll() {
    const src = this.hasUrlValue ? this.urlValue : null
    if (!src) return

    const separator = src.includes("?") ? "&" : "?"

    fetch(`${src}${separator}_poll=${Date.now()}`)
      .then(r => {
        if (!r.ok) throw new Error(`HTTP ${r.status}`)
        return r.text()
      })
      .then(html => {
        if (html.includes("life-preview-loading")) return

        clearInterval(this.messageInterval)
        clearInterval(this.pollInterval)

        const currentFrame = this.element.closest("turbo-frame#life_preview")
        if (!currentFrame) return

        currentFrame.outerHTML = `<turbo-frame id="life_preview" src="${src}${separator}_t=${Date.now()}"></turbo-frame>`
      })
      .catch(() => {})
  }
}
