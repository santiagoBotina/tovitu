import { Controller } from "@hotwired/stimulus"

// Conversion interstitial for signed-out visitors. Dismissible, no hard wall.
// Opens from the navbar heart or from any "tovitu:interest-prompt" event
// (e.g. the 2nd+ saved pet, or "View my saved pets" in the resume section).
//
// A11y: focus is moved into the dialog on open, Tab/Shift+Tab are trapped
// inside it, Escape and backdrop clicks close it, and focus returns to the
// previously-focused element on close.
const FOCUSABLE_SELECTOR = [
  'a[href]',
  'button:not([disabled])',
  'input:not([disabled])',
  'select:not([disabled])',
  'textarea:not([disabled])',
  '[tabindex]:not([tabindex="-1"])',
].join(", ")

export default class extends Controller {
  static targets = ["dialog", "closeButton", "trigger"]

  connect() {
    this._onPrompt = () => this.show()
    document.addEventListener("tovitu:interest-prompt", this._onPrompt)
    this._onKeydown = (event) => {
      if (event.key === "Escape" && this.isOpen()) {
        this.hide()
      } else if (event.key === "Tab" && this.isOpen()) {
        this.trapFocus(event)
      }
    }
    document.addEventListener("keydown", this._onKeydown)
  }

  disconnect() {
    document.removeEventListener("tovitu:interest-prompt", this._onPrompt)
    document.removeEventListener("keydown", this._onKeydown)
    if (this.isOpen()) document.body.classList.remove("overflow-hidden")
  }

  show() {
    if (!this.hasDialogTarget) return
    this._lastFocused = document.activeElement
    this.dialogTarget.classList.remove("hidden")
    this.dialogTarget.setAttribute("aria-hidden", "false")
    document.body.classList.add("overflow-hidden")
    window.requestAnimationFrame(() => {
      (this.hasCloseButtonTarget ? this.closeButtonTarget : this.dialogTarget).focus()
    })
  }

  hide() {
    if (!this.hasDialogTarget || this.dialogTarget.classList.contains("hidden")) return
    this.dialogTarget.classList.add("hidden")
    this.dialogTarget.setAttribute("aria-hidden", "true")
    document.body.classList.remove("overflow-hidden")
    this.restoreFocus()
  }

  hideFromEvent(event) {
    event.preventDefault()
    this.hide()
  }

  isOpen() {
    return this.hasDialogTarget && !this.dialogTarget.classList.contains("hidden")
  }

  trapFocus(event) {
    const focusable = this.focusableElements()
    if (focusable.length === 0) {
      event.preventDefault()
      this.dialogTarget.focus()
      return
    }
    const first = focusable[0]
    const last = focusable[focusable.length - 1]
    const active = document.activeElement
    if (event.shiftKey) {
      if (active === first || !this.dialogTarget.contains(active)) {
        event.preventDefault()
        last.focus()
      }
    } else if (active === last || !this.dialogTarget.contains(active)) {
      event.preventDefault()
      first.focus()
    }
  }

  focusableElements() {
    if (!this.hasDialogTarget) return []
    return Array.from(this.dialogTarget.querySelectorAll(FOCUSABLE_SELECTOR))
  }

  restoreFocus() {
    const target = this._lastFocused && document.contains(this._lastFocused)
      ? this._lastFocused
      : (this.hasTriggerTarget ? this.triggerTarget : null)
    if (target) target.focus()
    this._lastFocused = null
  }
}
