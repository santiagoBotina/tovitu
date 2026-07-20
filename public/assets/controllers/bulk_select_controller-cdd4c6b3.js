import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["selectAll", "checkbox", "bulkActions", "count"]

  connect() {
    this.update()
  }

  toggleAll(event) {
    const checked = event.target.checked
    this.checkboxTargets.forEach(cb => cb.checked = checked)
    this.update()
  }

  update() {
    const checked = this.checkboxTargets.filter(cb => cb.checked)
    const allChecked = checked.length === this.checkboxTargets.length && this.checkboxTargets.length > 0

    if (this.hasSelectAllTarget) {
      this.selectAllTarget.checked = allChecked
      this.selectAllTarget.indeterminate = checked.length > 0 && !allChecked
    }

    if (this.hasBulkActionsTarget) {
      this.bulkActionsTarget.style.display = checked.length > 0 ? "" : "none"
    }

    if (this.hasCountTarget) {
      this.countTarget.textContent = checked.length
    }
  }
}
