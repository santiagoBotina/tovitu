import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = [
    "question", "questionContainer", "progressBar", "progressText",
    "backButton", "nextButton", "nextButtonText", "skipButton",
    "selectedCount", "textInput", "completeForm", "skipField",
    "milestoneDot", "mascot", "progressTips", "personalityCard",
    "confettiTrigger"
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
    this.reducedMotion = window.matchMedia("(prefers-reduced-motion: reduce)").matches
    this.showQuestion(this.currentStepValue)
    this.updateProgress()
    this.updateMilestones()
    this.startTipRotation()
  }

  disconnect() {
    this.stopTipRotation()
  }

  nextQuestion() {
    const currentEl = this.questionTargets.find(
      q => parseInt(q.dataset.question) === this.currentStepValue
    )
    if (!currentEl) return

    if (!this.validateQuestion(currentEl)) return

    const answer = this.getAnswer(currentEl)
    this.saveAnswer(this.currentStepValue, answer)

    // Dispatch question:completed event
    this.dispatch("question:completed", {
      detail: { question: this.currentStepValue, answer: answer },
      bubbles: true
    })

    // Trigger mascot happy reaction
    this.triggerMascotReaction("happy")

    if (this.currentStepValue >= this.totalStepsValue) {
      this.completeOnboarding(false)
      return
    }

    this.currentStepValue++
    this.transitionToQuestion(this.currentStepValue)
    this.updateProgress()
    this.updateMilestones()
  }

  previousQuestion() {
    if (this.currentStepValue <= 1) return
    this.currentStepValue--
    this.transitionToQuestion(this.currentStepValue)
    this.updateProgress()
    this.updateMilestones()
  }

  skipOnboarding() {
    this.completeOnboarding(true)
  }

  async completeOnboarding(skip) {
    await Promise.all(this.pendingSaves)

    if (this.hasSkipFieldTarget) {
      this.skipFieldTarget.value = skip ? "true" : "false"
    }

    if (skip) {
      // Skip: redirect without personality card
      if (this.hasCompleteFormTarget) {
        this.completeFormTarget.requestSubmit()
      }
      return
    }

    // Show personality card before submitting
    if (!this.reducedMotion) {
      this.showPersonalityCard()
    }

    // Fire confetti
    this.dispatch("wizard:complete", { bubbles: true })

    // Trigger mascot celebration
    this.triggerMascotReaction("celebrate")

    // Submit after a brief delay for the celebration
    setTimeout(() => {
      if (this.hasCompleteFormTarget) {
        this.completeFormTarget.requestSubmit()
      }
    }, 2000)
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
        if (!this.reducedMotion) {
          // Tiered animation: scale(0.95) → scale(1) + fadeIn
          q.classList.add("opacity-0", "scale-95")
          requestAnimationFrame(() => {
            q.classList.remove("opacity-0", "scale-95")
            q.classList.add("transition-all", "duration-[400ms]", "ease-[cubic-bezier(0.16,1,0.3,1)]")
            requestAnimationFrame(() => {
              q.classList.remove("transition-all", "duration-[400ms]", "ease-[cubic-bezier(0.16,1,0.3,1)]")
            })
          })
        }
      } else {
        q.classList.add("hidden")
        q.classList.remove("opacity-0", "scale-95", "translate-x-4")
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

    const tipMessages = [
      this.element.dataset.tip1 || "Almost there! Your answers help us match you with the right tools.",
      this.element.dataset.tip2 || "Every great shelter started with a plan. You're building yours!",
      this.element.dataset.tip3 || "Fun fact: Shelters with complete profiles get 3x more adoption requests!",
      this.element.dataset.tip4 || "You're doing great! Just a few more questions."
    ]
    const tipIndex = Math.min(this.currentStepValue - 1, tipMessages.length - 1)

    this.progressTextTarget.textContent = `\u{1F43E} Question ${this.currentStepValue} of ${this.totalStepsValue} \u{2014} ${tipMessages[tipIndex]}`

    this.backButtonTarget.classList.toggle("invisible", this.currentStepValue <= 1)

    const isLast = this.currentStepValue >= this.totalStepsValue
    this.nextButtonTarget.querySelector("span").textContent = isLast
      ? this.nextButtonTarget.dataset.completeText || "Complete Profile"
      : this.nextButtonTarget.dataset.nextText || "Next"
  }

  // ─── Milestone System ───

  updateMilestones() {
    if (!this.hasMilestoneDotTarget) return

    const percent = ((this.currentStepValue - 1) / this.totalStepsValue) * 100
    const milestoneThresholds = [25, 50, 75, 100]

    this.milestoneDotTargets.forEach(dot => {
      const threshold = parseInt(dot.dataset.threshold)
      const reached = percent >= threshold

      dot.classList.toggle("bg-primary-500", reached)
      dot.classList.toggle("bg-neutral-200", !reached)
      dot.classList.toggle("diamond-pulse", reached && !this.reducedMotion)

      if (reached && dot.dataset.triggered !== "true") {
        dot.dataset.triggered = "true"
        // Only sparkle on first reach
        if (!this.reducedMotion) {
          dot.classList.add("level-up-glow")
          setTimeout(() => dot.classList.remove("level-up-glow"), 800)
        }
      }
    })
  }

  // ─── Mascot System ───

  triggerMascotReaction(type) {
    if (!this.hasMascotTarget || this.reducedMotion) return

    const mascot = this.mascotTarget
    mascot.classList.remove("mascot-bounce")

    // Force reflow to restart animation
    void mascot.offsetWidth

    if (type === "celebrate") {
      // Repeated bounce for celebration
      let count = 0
      const maxBounces = 3
      const bounceInterval = setInterval(() => {
        mascot.classList.add("mascot-bounce")
        setTimeout(() => mascot.classList.remove("mascot-bounce"), 600)
        count++
        if (count >= maxBounces) clearInterval(bounceInterval)
      }, 700)
    } else {
      mascot.classList.add("mascot-bounce")
    }
  }

  // ─── Personality Card ───

  showPersonalityCard() {
    const card = this.element.querySelector("[data-onboarding-target=\"personalityCard\"]")
    if (!card) return

    card.classList.remove("hidden")
    card.classList.add("opacity-0", "scale-95")

    requestAnimationFrame(() => {
      card.classList.remove("opacity-0", "scale-95")
      card.classList.add("transition-all", "duration-500", "ease-[cubic-bezier(0.16,1,0.3,1)]")
      setTimeout(() => {
        card.classList.remove("transition-all", "duration-500", "ease-[cubic-bezier(0.16,1,0.3,1)]")
      }, 500)
    })
  }

  // ─── Tips Rotation ───

  startTipRotation() {
    if (this.reducedMotion) return
    this.stopTipRotation()
    this._tipInterval = setInterval(() => {
      if (!this.hasProgressTipsTarget) return
      const tips = this.progressTipsTarget.querySelectorAll("[data-tip]")
      const active = this.progressTipsTarget.querySelector("[data-tip].active")
      if (tips.length === 0) return

      let nextIdx = 0
      if (active) {
        active.classList.remove("active")
        const currentIdx = Array.from(tips).indexOf(active)
        nextIdx = (currentIdx + 1) % tips.length
      }
      tips[nextIdx].classList.add("active")
    }, 5000)
  }

  stopTipRotation() {
    if (this._tipInterval) {
      clearInterval(this._tipInterval)
      this._tipInterval = null
    }
  }
}
