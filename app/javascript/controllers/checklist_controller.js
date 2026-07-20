import { Controller } from "@hotwired/stimulus"

// Manages the dashboard checklist gamification
// Handles checkmark animations, level-up celebrations, encouragement rotation
export default class extends Controller {
  static targets = ["item", "progressBar", "levelBadge", "encouragement", "checkmark", "tip"]
  static values = {
    currentLevel: Number,
    completedCount: Number,
    totalSteps: Number,
    levels: Array
  }

  connect() {
    this.reducedMotion = window.matchMedia("(prefers-reduced-motion: reduce)").matches
    this.celebrationFlags = new Set()
    this.loadCelebrationFlags()

    // Mark already-celebrated items on connect
    this.itemTargets.forEach(item => {
      if (item.dataset.done === "true") {
        const level = parseInt(item.dataset.level)
        if (level) this.celebrationFlags.add(`level-${level}`)
      }
    })

    // Detect newly completed items by comparing with previous state
    const prevState = this._previousState
    if (prevState) {
      this.itemTargets.forEach(item => {
        const key = item.dataset.key
        const nowDone = item.dataset.done === "true"
        const wasDone = prevState[key] === true

        if (nowDone && !wasDone) {
          this.celebrateItem(item)
        }
      })
    }

    // Store current state for next comparison
    this._previousState = {}
    this.itemTargets.forEach(item => {
      this._previousState[item.dataset.key] = item.dataset.done === "true"
    })

    // Update encouragement on connect
    this.updateEncouragement()

    // Start tip rotation
    this.startTipRotation()
  }

  disconnect() {
    this.stopTipRotation()
  }

  celebrateItem(element) {
    // Play checkmark burst animation
    const checkmark = element.querySelector("[data-checklist-target=\"checkmark\"]")
    if (checkmark && !this.reducedMotion) {
      checkmark.classList.add("check-burst")
    }

    // Update progress bar with pulse
    if (this.hasProgressBarTarget && !this.reducedMotion) {
      this.progressBarTarget.classList.add("progress-shimmer-fast")
      setTimeout(() => {
        this.progressBarTarget.classList.remove("progress-shimmer-fast")
      }, 800)
    }

    // Mark as celebrated to prevent re-animation
    element.dataset.celebrated = "true"

    // Recompute completed count and update value
    const doneCount = this.itemTargets.filter(el => el.dataset.done === "true").length
    this.completedCountValue = doneCount

    // Check if a level threshold was crossed
    const newLevel = this.computeLevel()
    if (newLevel > this.currentLevelValue) {
      this.currentLevelValue = newLevel
      const levelInfo = this.levelsValue[newLevel - 1] || {}

      // Fire level-up celebration (only first time per level)
      const flag = `level-${newLevel}`
      if (!this.celebrationFlags.has(flag)) {
        this.celebrationFlags.add(flag)
        this.saveCelebrationFlags()

        // Dispatch level-up event for confetti controller
        this.dispatch("checklist:level-up", {
          detail: { level: newLevel, title: levelInfo.title },
          bubbles: true
        })

        // Show level-up glow on badge
        if (this.hasLevelBadgeTarget) {
          this.levelBadgeTarget.classList.add("level-up-glow")
          setTimeout(() => {
            this.levelBadgeTarget.classList.remove("level-up-glow")
          }, 800)
        }
      }
    }

    // Update encouragement
    this.updateEncouragement()
  }

  computeLevel() {
    const done = this.completedCountValue
    if (done === 0) return 1
    if (done <= 2) return 2
    if (done <= 4) return 3
    if (done === 5) return 4
    if (done >= 6) return 5
    return 1
  }

  updateEncouragement() {
    if (!this.hasEncouragementTarget) return

    const done = this.completedCountValue
    const total = this.totalStepsValue

    if (done >= total) {
      this.encouragementTarget.textContent = this.encouragementTarget.dataset.allDone || "🎉 Amazing! Your shelter is fully set up and ready for adopters!"
    } else {
      this.encouragementTarget.textContent = this.encouragementTarget.dataset.completed
        ? this.encouragementTarget.dataset.completed.replace("%{count}", done).replace("%{total}", total)
        : `You completed ${done} of ${total} steps! Keep going!`
    }
  }

  startTipRotation() {
    this.stopTipRotation()
    this._tipInterval = setInterval(() => {
      const tips = this.tipTargets
      const active = tips.find(t => t.classList.contains("active"))
      if (tips.length === 0) return

      let nextIdx = 0
      if (active) {
        active.classList.remove("active")
        const currentIdx = tips.indexOf(active)
        nextIdx = (currentIdx + 1) % tips.length
      }
      tips[nextIdx]?.classList.add("active")
    }, 5000)
  }

  stopTipRotation() {
    if (this._tipInterval) {
      clearInterval(this._tipInterval)
      this._tipInterval = null
    }
  }

  // Persist celebration flags across page loads via sessionStorage
  loadCelebrationFlags() {
    try {
      const saved = sessionStorage.getItem("tovitu_checklist_celebrations")
      if (saved) {
        const flags = JSON.parse(saved)
        flags.forEach(f => this.celebrationFlags.add(f))
      }
    } catch (e) {
      // sessionStorage not available
    }
  }

  saveCelebrationFlags() {
    try {
      sessionStorage.setItem(
        "tovitu_checklist_celebrations",
        JSON.stringify(Array.from(this.celebrationFlags))
      )
    } catch (e) {
      // sessionStorage not available
    }
  }
}
