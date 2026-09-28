import { Controller } from "@hotwired/stimulus"

// "My Location" card in profile settings. Handles device re-detection, manual
// entry, and dismiss. All writes go to the settings location endpoint and the
// server responds with a turbo_stream replacing this card (REQ-48-4).
// Manual entry submits through the normal Turbo form; device detection fills
// the hidden fields on that same form and submits it.
export default class extends Controller {
  static targets = ["message", "deviceButton", "actions", "manualForm", "saveButton", "intentField"]

  static values = {
    saveUrl: String,
    permissionDeniedMessage: String,
    deviceUnsupportedMessage: String,
    timeoutMessage: String,
    positionUnavailableMessage: String,
    cityRequiredMessage: String
  }

  connect() {
    this.geoSupported = "geolocation" in navigator
    this.secureContext = window.isSecureContext !== false
    if (!this.geoSupported || !this.secureContext) {
      if (this.hasDeviceButtonTarget) this.deviceButtonTarget.classList.add("hidden")
    }
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
      this._submitForm({ intent: "device", latitude, longitude })
    } catch (error) {
      this.handleGeoError(error)
      this.setBusy(false)
    }
  }

  // Submits the visible manual form through Turbo. Device detection updates the
  // static `intent` hidden field and appends coords; the server's turbo_stream
  // response replaces the card.
  _submitForm(payload) {
    const form = this.manualFormTarget
    this._clearPayloadFields(form)
    this._fillPayloadFields(form, payload)
    form.requestSubmit()
  }

  showManual() {
    if (this.hasActionsTarget) this.actionsTarget.classList.add("hidden")
    if (this.hasManualFormTarget) this.manualFormTarget.classList.remove("hidden")
  }

  revealManual() {
    this.showManual()
  }

  cancelManual() {
    if (this.hasManualFormTarget) this.manualFormTarget.classList.add("hidden")
    if (this.hasActionsTarget) this.actionsTarget.classList.remove("hidden")
  }

  dismiss() {
    this.element.classList.add("hidden")
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

  _clearPayloadFields(form) {
    form.querySelectorAll("input[data-location-payload]").forEach((input) => input.remove())
  }

  _fillPayloadFields(form, payload) {
    for (const [key, value] of Object.entries(payload)) {
      if (key === "intent" && this.hasIntentFieldTarget) {
        this.intentFieldTarget.value = value
      } else {
        form.appendChild(this._hiddenField(key, value))
      }
    }
  }

  _hiddenField(name, value) {
    const input = document.createElement("input")
    input.type = "hidden"
    input.name = name
    input.value = value
    input.setAttribute("data-location-payload", "true")
    return input
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