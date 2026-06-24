import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static values = {
    confirmText: { type: String, default: "Confirm" },
    cancelText: { type: String, default: "Cancel" }
  }

  connect() {
    this.modalElement = null
    this.promiseResolve = null
    this.triggerElement = null
    this.isOpen = false
    this._keydownHandler = null

    Turbo.setConfirmMethod(this._confirmMethod.bind(this))

    this._beforeVisitHandler = () => {
      if (this.isOpen) this._dismiss()
    }
    document.addEventListener("turbo:before-visit", this._beforeVisitHandler)
  }

  disconnect() {
    document.removeEventListener("turbo:before-visit", this._beforeVisitHandler)
    this._removeModalFromDOM()
    if (this._keydownHandler) {
      document.removeEventListener("keydown", this._keydownHandler)
    }
    document.body.classList.remove("overflow-hidden")
  }

  _confirmMethod(message, element) {
    if (this.isOpen) return false

    this.isOpen = true
    this.triggerElement = element

    return new Promise((resolve) => {
      this.promiseResolve = resolve
      this._renderModal(message, element)
    })
  }

  _renderModal(message, element) {
    this._removeModalFromDOM()

    const isDanger = this._isDestructive(element, message)
    const titleId = "confirm-modal-title"

    const wrapper = document.createElement("div")
    wrapper.id = "confirm-modal"
    wrapper.setAttribute("role", "dialog")
    wrapper.setAttribute("aria-modal", "true")
    wrapper.setAttribute("aria-labelledby", titleId)
    wrapper.className = "fixed inset-0 z-[100] flex items-center justify-center p-4"

    const backdrop = document.createElement("div")
    backdrop.className =
      "absolute inset-0 bg-black/40 backdrop-blur-sm transition-opacity duration-200 ease-out opacity-0"

    const panel = document.createElement("div")
    panel.className =
      "relative bg-white rounded-2xl shadow-2xl p-6 max-w-sm w-full transform scale-95 transition-all duration-200 ease-out opacity-0"

    const iconHtml = isDanger
      ? `<div class="w-12 h-12 rounded-full bg-danger/10 flex items-center justify-center mx-auto mb-4">
          <svg class="w-6 h-6 text-danger" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2" aria-hidden="true">
            <path stroke-linecap="round" stroke-linejoin="round" d="M12 9v3.75m-9.303 3.376c-.866 1.5.217 3.374 1.948 3.374h14.71c1.73 0 2.813-1.874 1.948-3.374L13.949 3.378c-.866-1.5-3.032-1.5-3.898 0L2.697 16.126zM12 15.75h.007v.008H12v-.008z" />
          </svg>
        </div>`
      : `<div class="w-12 h-12 rounded-full bg-primary-50 flex items-center justify-center mx-auto mb-4">
          <svg class="w-6 h-6 text-primary-500" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2" aria-hidden="true">
            <path stroke-linecap="round" stroke-linejoin="round" d="M9.879 7.519c1.171-1.025 3.071-1.025 4.242 0 1.172 1.025 1.172 2.687 0 3.712-.203.179-.43.326-.67.442-.745.361-1.45.999-1.45 1.827v.75M21 12a9 9 0 11-18 0 9 9 0 0118 0zm-9 5.25h.008v.008H12v-.008z" />
          </svg>
        </div>`

    const confirmBtnClass = isDanger
      ? "bg-danger hover:bg-red-600 text-white focus:ring-danger"
      : "bg-primary-500 hover:bg-primary-600 text-white focus:ring-primary-500"

    panel.innerHTML = `
      ${iconHtml}
      <h3 id="${titleId}" class="text-lg font-semibold text-neutral-800 text-center mb-6">
        ${this._escapeHtml(message)}
      </h3>
      <div class="flex gap-3">
        <button type="button"
                class="cancel-btn flex-1 px-4 py-2.5 rounded-xl text-sm font-medium bg-neutral-100 text-neutral-600 hover:bg-neutral-200 transition-colors duration-150 focus:outline-none focus:ring-2 focus:ring-neutral-400">
          ${this._escapeHtml(this.cancelTextValue)}
        </button>
        <button type="button"
                class="confirm-btn flex-1 px-4 py-2.5 rounded-xl text-sm font-medium transition-colors duration-150 focus:outline-none focus:ring-2 focus:ring-offset-2 ${confirmBtnClass}">
          ${this._escapeHtml(this.confirmTextValue)}
        </button>
      </div>
    `

    wrapper.appendChild(backdrop)
    wrapper.appendChild(panel)
    document.body.appendChild(wrapper)

    const cancelBtn = panel.querySelector(".cancel-btn")
    const confirmBtn = panel.querySelector(".confirm-btn")

    cancelBtn.addEventListener("click", () => this._cancel())
    confirmBtn.addEventListener("click", () => this._confirm())
    backdrop.addEventListener("click", () => this._cancel())

    this._focusableElements = Array.from(
      panel.querySelectorAll('button, [href], input, select, textarea, [tabindex]:not([tabindex="-1"])')
    )

    cancelBtn.focus()

    this._keydownHandler = (e) => {
      if (e.key === "Escape") {
        e.preventDefault()
        this._cancel()
        return
      }
      if (e.key === "Tab") {
        this._trapFocus(e)
      }
    }
    document.addEventListener("keydown", this._keydownHandler)

    this.modalElement = wrapper
    this.modalBackdrop = backdrop
    this.modalPanel = panel

    requestAnimationFrame(() => {
      backdrop.classList.remove("opacity-0")
      requestAnimationFrame(() => {
        panel.classList.remove("opacity-0", "scale-95")
      })
    })

    document.body.classList.add("overflow-hidden")
  }

  _trapFocus(e) {
    if (!this._focusableElements || this._focusableElements.length === 0) return

    const first = this._focusableElements[0]
    const last = this._focusableElements[this._focusableElements.length - 1]

    if (e.shiftKey) {
      if (document.activeElement === first) {
        e.preventDefault()
        last.focus()
      }
    } else {
      if (document.activeElement === last) {
        e.preventDefault()
        first.focus()
      }
    }
  }

  _cancel() {
    this._dismiss()
    this._resolvePromise(false)
  }

  _confirm() {
    this._dismiss()
    this._resolvePromise(true)
  }

  _dismiss() {
    if (!this.modalElement) return

    if (this.modalBackdrop) {
      this.modalBackdrop.classList.add("opacity-0")
    }
    if (this.modalPanel) {
      this.modalPanel.classList.add("opacity-0", "scale-95")
    }

    if (this._keydownHandler) {
      document.removeEventListener("keydown", this._keydownHandler)
      this._keydownHandler = null
    }

    document.body.classList.remove("overflow-hidden")

    if (this.triggerElement && typeof this.triggerElement.focus === "function") {
      setTimeout(() => {
        try { this.triggerElement.focus() } catch (_) {}
      }, 50)
    }

    setTimeout(() => {
      this._removeModalFromDOM()
    }, 200)
  }

  _removeModalFromDOM() {
    if (this.modalElement && this.modalElement.parentNode) {
      this.modalElement.parentNode.removeChild(this.modalElement)
    }
    this.modalElement = null
    this.modalBackdrop = null
    this.modalPanel = null
    this._focusableElements = null
  }

  _resolvePromise(value) {
    if (this.promiseResolve) {
      this.promiseResolve(value)
      this.promiseResolve = null
    }
    this.isOpen = false
  }

  _isDestructive(element, message) {
    if (!element) {
      return this._messageHasDangerKeywords(message)
    }

    const classList = element.classList
    if (classList && classList.length > 0) {
      for (let i = 0; i < classList.length; i++) {
        if (classList[i].includes("danger")) {
          return true
        }
      }
    }

    return this._messageHasDangerKeywords(message)
  }

  _messageHasDangerKeywords(message) {
    if (!message) return false
    const msg = message.toLowerCase()
    return msg.includes("delete") || msg.includes("remove")
  }

  _escapeHtml(str) {
    const div = document.createElement("div")
    div.textContent = str
    return div.innerHTML
  }
}
