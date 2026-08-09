import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["button", "toggleable", "accent"]

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
      const isIndividualLike = btn.dataset.role === "adopter" || btn.dataset.role === "individual"
      btn.classList.toggle("bg-primary-500", isActive && isIndividualLike)
      btn.classList.toggle("bg-secondary-500", isActive && !isIndividualLike)
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

    // Elements whose accent follows the selected role palette (purple =
    // individual, teal = shelter). Each element declares its own class sets
    // via data-role-toggle-accent-primary / data-role-toggle-accent-secondary.
    this.accentTargets.forEach(el => {
      const isShelter = this.currentRole === "shelter"
      const active = (isShelter ? el.dataset.roleToggleAccentSecondary : el.dataset.roleToggleAccentPrimary) || ""
      const inactive = (isShelter ? el.dataset.roleToggleAccentPrimary : el.dataset.roleToggleAccentSecondary) || ""
      active.split(" ").filter(Boolean).forEach(c => el.classList.add(c))
      inactive.split(" ").filter(Boolean).forEach(c => el.classList.remove(c))
    })

    const roleField = this.element.querySelector("[data-role-toggle-role-field]")
    if (roleField) {
      roleField.value = this.submitRoleFor(this.currentRole)
    }
  }

  // The UI toggle speaks display roles ("individual" | "shelter") but the
  // registration API accepts real roles ("individual" | "shelter_admin").
  // Pages that need this mapping expose the shelter submit role via
  // data-role-toggle-submit-role (defaults to "shelter_admin").
  submitRoleFor(displayRole) {
    if (displayRole === "shelter") {
      return this.element.dataset.roleToggleSubmitRole || "shelter_admin"
    }
    return "individual"
  }
}
