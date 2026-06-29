import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["button", "toggleable"]

  connect() {
    this.currentRole = this.element.dataset.roleToggleRole || "adopter"
    this.sync()
  }

  selectRole(event) {
    const role = event.currentTarget.dataset.role
    if (role === this.currentRole) return
    this.currentRole = role
    this.sync()
  }

  sync() {
    this.buttonTargets.forEach(btn => {
      const isActive = btn.dataset.role === this.currentRole
      const isAdopter = btn.dataset.role === "adopter"
      const bgActive = isAdopter ? "bg-primary-500" : "bg-secondary-500"
      btn.classList.toggle("bg-primary-500", isActive && isAdopter)
      btn.classList.toggle("bg-secondary-500", isActive && !isAdopter)
      btn.classList.toggle("text-white", isActive)
      btn.classList.toggle("shadow-sm", isActive)
      btn.classList.toggle("bg-transparent", !isActive)
      btn.classList.toggle("text-neutral-600", !isActive)
      btn.classList.toggle("hover:text-neutral-800", !isActive)
      btn.setAttribute("aria-pressed", isActive ? "true" : "false")
    })

    this.toggleableTargets.forEach(el => {
      el.classList.toggle("hidden", el.dataset.role !== this.currentRole)
    })

    const roleField = this.element.querySelector("[data-role-toggle-role-field]")
    if (roleField) {
      roleField.value = this.currentRole
    }
  }
}
