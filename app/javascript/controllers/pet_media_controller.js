import { Controller } from "@hotwired/stimulus"

// Pet media page: auto-submits the multi-file upload as soon as files are
// chosen and shows the number of files selected. The grid + toasts come back
// via turbo_stream (handled by the photo controller). The URL form is a plain
// Turbo form and needs no special handling.
export default class extends Controller {
  static targets = ["files", "uploadForm", "count"]

  submitFiles() {
    const count = this.filesTarget.files.length
    if (count === 0) return
    this.updateCount(count)
    this.uploadFormTarget.requestSubmit()
  }

  updateCount(count) {
    if (!this.hasCountTarget) return
    if (count > 0) {
      this.countTarget.classList.remove("hidden")
      this.countTarget.textContent = this.countTarget.dataset.countTemplate.replace("%{count}", String(count))
    } else {
      this.countTarget.classList.add("hidden")
    }
  }
}