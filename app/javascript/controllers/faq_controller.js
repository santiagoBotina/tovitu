import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["input", "answer", "loading", "content", "error"]
  static values = { shelterId: Number, applicationToken: String }

  ask() {
    const question = this.inputTarget.value.trim()
    if (!question) return

    this.answerTarget.classList.remove("hidden")
    this.loadingTarget.classList.remove("hidden")
    this.contentTarget.classList.add("hidden")
    this.errorTarget.classList.add("hidden")

    const url = this.applicationTokenValue
      ? `/adoption_applications/${this.applicationTokenValue}/rag_queries`
      : `/shelters/${this.shelterIdValue}/rag_queries`

    fetch(url, {
      method: "POST",
      headers: { "Content-Type": "application/json", "X-CSRF-Token": document.querySelector("[name='csrf-token']").content },
      body: JSON.stringify({ question })
    })
      .then(r => r.json())
      .then(data => {
        this.loadingTarget.classList.add("hidden")
        this.contentTarget.classList.remove("hidden")
        this.contentTarget.innerHTML = data.answer
      })
      .catch(() => {
        this.loadingTarget.classList.add("hidden")
        this.errorTarget.classList.remove("hidden")
      })
  }
}
