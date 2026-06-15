import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = [
    "question", "questionContainer", "progressBar", "progressText",
    "backButton", "nextButton", "nextButtonText", "skipButton",
    "selectedCount", "textInput", "completeForm", "skipField"
  ]

  static values = {
    currentStep: Number,
    totalSteps: Number,
    saveUrl: String,
    completeUrl: String,
    role: String
  }

  connect() {
    this.pendingSaves = []
    this.showQuestion(this.currentStepValue)
    this.updateProgress()
  }

  nextQuestion() {
    const currentEl = this.questionTargets.find(
      q => parseInt(q.dataset.question) === this.currentStepValue
    )
    if (!currentEl) return

    if (!this.validateQuestion(currentEl)) return

    const answer = this.getAnswer(currentEl)
    this.saveAnswer(this.currentStepValue, answer)

    if (this.currentStepValue >= this.totalStepsValue) {
      this.completeOnboarding(false)
      return
    }

    this.currentStepValue++
    this.transitionToQuestion(this.currentStepValue)
    this.updateProgress()
  }

  previousQuestion() {
    if (this.currentStepValue <= 1) return
    this.currentStepValue--
    this.transitionToQuestion(this.currentStepValue)
    this.updateProgress()
  }

  skipOnboarding() {
    this.completeOnboarding(true)
  }

  async completeOnboarding(skip) {
    await Promise.all(this.pendingSaves)

    if (this.hasSkipFieldTarget) {
      this.skipFieldTarget.value = skip ? "true" : "false"
    }
    if (this.hasCompleteFormTarget) {
      this.completeFormTarget.requestSubmit()
    }
  }

  validateQuestion(element) {
    const type = element.dataset.type
    const container = element.querySelector("[data-controller]")

    if (type === "multi-select") {
      const selected = element.querySelectorAll("[data-multi-select-target=\"chip\"].bg-primary-100")
      const errorMsg = element.querySelector("[data-multi-select-target=\"errorMessage\"]")
      if (selected.length === 0) {
        if (errorMsg) errorMsg.classList.remove("hidden")
        return false
      }
      if (errorMsg) errorMsg.classList.add("hidden")
    }

    return true
  }

  getAnswer(element) {
    const type = element.dataset.type
    const key = element.dataset.key

    if (type === "multi-select") {
      const selected = element.querySelectorAll("[data-multi-select-target=\"chip\"].bg-primary-100")
      return Array.from(selected).map(chip => chip.dataset.value)
    }

    if (type === "single-select") {
      const selected = element.querySelector("[data-single-select-target=\"option\"].bg-primary-50")
      return selected ? selected.dataset.value : ""
    }

    if (type === "text") {
      const textarea = element.querySelector("textarea")
      return textarea ? textarea.value : ""
    }

    return ""
  }

  saveAnswer(questionNumber, answer) {
    if (answer === "" || (Array.isArray(answer) && answer.length === 0)) return

    const promise = fetch(this.saveUrlValue, {
      method: "PATCH",
      headers: {
        "X-CSRF-Token": document.querySelector("[name='csrf-token']").content,
        "Content-Type": "application/json"
      },
      body: JSON.stringify({
        question_number: questionNumber,
        answer: answer
      })
    }).catch(() => {})

    this.pendingSaves.push(promise)
  }

  transitionToQuestion(step) {
    this.questionTargets.forEach(q => {
      const num = parseInt(q.dataset.question)
      if (num === step) {
        q.classList.remove("hidden")
        q.classList.add("opacity-0", "translate-x-4")
        requestAnimationFrame(() => {
          q.classList.remove("opacity-0", "translate-x-4")
        })
      } else {
        q.classList.add("hidden")
        q.classList.remove("opacity-0", "translate-x-4")
      }
    })

    this.showQuestion(step)
  }

  showQuestion(step) {
    this.questionTargets.forEach(q => {
      const num = parseInt(q.dataset.question)
      q.classList.toggle("hidden", num !== step)
    })
  }

  updateProgress() {
    const percent = ((this.currentStepValue - 1) / this.totalStepsValue) * 100
    this.progressBarTarget.style.width = `${percent}%`
    this.progressTextTarget.textContent = this.progressTextTarget.textContent.replace(
      /\d+ of \d+/,
      `${this.currentStepValue} of ${this.totalStepsValue}`
    )

    this.backButtonTarget.classList.toggle("invisible", this.currentStepValue <= 1)

    const isLast = this.currentStepValue >= this.totalStepsValue
    this.nextButtonTarget.querySelector("span").textContent = isLast
      ? this.nextButtonTarget.dataset.completeText || "Complete Profile"
      : this.nextButtonTarget.dataset.nextText || "Next"
  }
}
