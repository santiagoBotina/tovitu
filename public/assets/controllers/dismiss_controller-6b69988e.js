import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  connect() {
    setTimeout(() => this.hide(), 8000)
  }

  hide() {
    this.element.remove()
  }
}
