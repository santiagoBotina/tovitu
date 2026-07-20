import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="notification-bell"
export default class extends Controller {
  static targets = ["dropdown", "badge", "button"]
  static values = { unreadCount: Number }

  connect() {
    this.pollInterval = null
    this.loadUnreadCount()
    this.startPolling()
  }

  disconnect() {
    this.stopPolling()
  }

  toggle() {
    if (this.dropdownTarget.classList.contains("hidden")) {
      this.show()
    } else {
      this.hide()
    }
  }

  show() {
    this.dropdownTarget.classList.remove("hidden")
    // Trigger animation
    requestAnimationFrame(() => {
      this.dropdownTarget.classList.remove("opacity-0", "scale-95")
      this.dropdownTarget.classList.add("opacity-100", "scale-100")
    })
    document.addEventListener("click", this._handleClickOutside)
    this.loadDropdownNotifications()
  }

  hide() {
    this.dropdownTarget.classList.add("opacity-0", "scale-95")
    this.dropdownTarget.classList.remove("opacity-100", "scale-100")
    // After animation
    setTimeout(() => {
      this.dropdownTarget.classList.add("hidden")
    }, 150)
    document.removeEventListener("click", this._handleClickOutside)
  }

  markAllRead(event) {
    event.preventDefault()
    fetch("/notifications/mark_all_read", {
      method: "PATCH",
      headers: { "X-CSRF-Token": this._csrfToken(), "Accept": "application/json" }
    }).then(() => {
      this.loadUnreadCount()
      // Update all items in dropdown to show as read
      this.dropdownTarget.querySelectorAll(".bg-primary-50\\/30").forEach(el => {
        el.classList.remove("bg-primary-50/30")
      })
      this.dropdownTarget.querySelectorAll(".bg-primary-500").forEach(el => {
        el.classList.remove("bg-primary-500")
        el.classList.add("bg-transparent")
      })
    })
  }

  loadUnreadCount() {
    fetch("/notifications/unread_count", {
      headers: { "Accept": "application/json" }
    })
      .then(response => response.json())
      .then(data => {
        this.updateBadge(data.count)
      })
      .catch(() => {})
  }

  loadDropdownNotifications() {
    // For now the dropdown data is rendered server-side
    // Future: fetch via Turbo Stream
  }

  updateBadge(count) {
    const badge = this.badgeTarget
    if (count > 0) {
      badge.classList.remove("hidden")
      badge.textContent = count > 9 ? "9+" : count
    } else {
      badge.classList.add("hidden")
    }
  }

  startPolling() {
    this.pollInterval = setInterval(() => {
      this.loadUnreadCount()
    }, 30000) // Poll every 30 seconds
  }

  stopPolling() {
    if (this.pollInterval) {
      clearInterval(this.pollInterval)
      this.pollInterval = null
    }
  }

  _handleClickOutside = (event) => {
    if (!this.element.contains(event.target)) {
      this.hide()
    }
  }

  _csrfToken() {
    return document.querySelector('meta[name="csrf-token"]')?.getAttribute("content")
  }
}
