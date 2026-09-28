import { Controller } from "@hotwired/stimulus"

// Optional location step in the individual onboarding wizard (question 9).
// Drives the three actions (device / manual / skip) against the dedicated
// location endpoint and, on success, advances the wizard to completion.
// Degrades gracefully: unsupported / denied / timeout all fall back to the
// always-available manual entry (REQ-48-7).
export default class extends Controller {
  static targets = ["message", "deviceButton", "manualForm", "saveButton", "actions"]

  static values = {
    saveUrl: String,
    permissionDeniedMessage: String,
    deviceUnsupportedMessage: String,
    timeoutMessage: String,
    positionUnavailableMessage: String,
    cityRequiredMessage: String,
    savingMessage: String
  }

  connect() {
    this.geoSupported = "geolocation" in navigator
    this.secureContext = window.isSecureContext !== false
    this.saved = false
  }

  async useDevice() {
    if (!this.geoSupported || !this.secureContext) {
      this.showMessage(this.deviceUnsupportedMessageValue)
      this.revealManual()
      return
    }

    this.setBusy(true)
    try {
      const position = await this._getCurrentPosition()
      const { latitude, longitude } = position.coords
      await this.save({ intent: "device", latitude, longitude })
    } catch (error) {
      this.handleGeoError(error)
    } finally {
      this.setBusy(false)
    }
  }

  async skip() {
    this.setBusy(true)
    try {
      await this.save({ intent: "skip" })
    } finally {
      this.setBusy(false)
    }
  }

  async submitManual(event) {
    event.preventDefault()
    const form = this.manualFormTarget
    const city = form.querySelector("#city")?.value?.trim() || form.querySelector("[name='city']")?.value?.trim()
    const region = form.querySelector("[name='region']")?.value?.trim() || ""
    const country = form.querySelector("[name='country']")?.value?.trim() || ""

    if (!city) {
      this.showMessage(this.cityRequiredMessageValue || "")
      return
    }

    this.setBusy(true)
    try {
      await this.save({ intent: "manual", city, region, country })
    } finally {
      this.setBusy(false)
    }
  }

  showManual() {
    if (this.hasActionsTarget) this.actionsTarget.classList.add("hidden")
    if (this.hasManualFormTarget) this.manualFormTarget.classList.remove("hidden")
  }

  revealManual() {
    this.showManual()
  }

  async save(payload) {
    const response = await fetch(this.saveUrlValue, {
      method: "PATCH",
      headers: {
        "Content-Type": "application/json",
        "Accept": "application/json",
        "X-CSRF-Token": document.querySelector("meta[name='csrf-token']")?.content
      },
      body: JSON.stringify(payload)
    })

    const json = await response.json()

    if (json.success) {
      this.saved = true
      this.completeWizard()
      return
    }

    this.showMessage(Array(json.errors || []).join(", ") || this.positionUnavailableMessageValue)
    this.revealManual()
  }

  handleGeoError(error) {
    const messages = {
      1: this.permissionDeniedMessageValue,
      2: this.positionUnavailableMessageValue,
      3: this.timeoutMessageValue
    }
    this.showMessage(messages[error.code] || this.positionUnavailableMessageValue)
    this.revealManual()
  }

  _getCurrentPosition() {
    return new Promise((resolve, reject) => {
      navigator.geolocation.getCurrentPosition(resolve, reject, {
        enableHighAccuracy: false,
        timeout: 10000,
        maximumAge: 600000
      })
    })
  }

  // After a successful decision, advance the onboarding wizard to completion.
  completeWizard() {
    const wizardElement = this.element.closest("[data-controller='onboarding']")
    if (!wizardElement) return

    const wizard = this.application.getControllerForElementAndIdentifier(wizardElement, "onboarding")
    if (wizard && typeof wizard.completeOnboarding === "function") {
      wizard.completeOnboarding(false)
    }
  }

  showMessage(text) {
    if (!this.hasMessageTarget) return
    this.messageTarget.textContent = text
    this.messageTarget.classList.remove("hidden")
  }

  setBusy(busy) {
    if (this.hasDeviceButtonTarget) this.deviceButtonTarget.disabled = busy
    if (this.hasSaveButtonTarget) this.saveButtonTarget.disabled = busy
  }
}