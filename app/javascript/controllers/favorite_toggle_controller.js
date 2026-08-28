import { Controller } from "@hotwired/stimulus"
import { showToast } from "utils/toast"

// Optimistic save/remove for signed-in users.
//
// Tapping the heart flips the visual state immediately (filled ↔ outline) and
// dispatches the backend request in the background. The UI converges with the
// server response: on success the state is confirmed, on failure it reverts
// and the user is notified in plain language.
//
// Rapid toggling follows "last action wins": while a request is in flight, the
// newest desired state is queued and dispatched as soon as the in-flight
// request settles, so no interaction is lost and no race leaves the UI wrong.
//
// Multiple controls for the same pet (the circle heart on the profile hero and
// the labeled sidebar button) share one per-pet queue and stay in sync via the
// tovitu:favorite-changed event, so toggling either control converges to the
// last action across both.
//
// The form still submits normally (turbo_stream) when JavaScript is disabled.
const queues = new Map()

function queueFor(petId) {
  if (!queues.has(petId)) queues.set(petId, { pending: null, inFlight: false, controllers: new Set() })
  return queues.get(petId)
}

// Removes the per-pet queue once no controller uses it and nothing is in
// flight, so long sessions don't accumulate entries for every pet ever seen.
function releaseQueue(petId, queue) {
  if (queue.controllers.size === 0 && !queue.inFlight && queue.pending === null) {
    queues.delete(petId)
  }
}

export default class extends Controller {
  static targets = ["button", "icon", "label"]
  static values = {
    petId: Number,
    saved: Boolean,
    saveLabel: String,
    unsaveLabel: String,
    errorMessage: String,
    dismissLabel: String,
    controlSavedClass: String,
    controlUnsavedClass: String,
    iconSavedClass: String,
    iconUnsavedClass: String,
  }

  connect() {
    this.queue = queueFor(this.petIdValue)
    this.queue.controllers.add(this)
    this._onFavoriteChanged = (event) => {
      if (event.detail?.petId !== this.petIdValue) return
      if (event.detail?.source === this.element) return
      if (event.detail.saved === this.isSaved()) return
      this.savedValue = event.detail.saved
      this.render()
    }
    document.addEventListener("tovitu:favorite-changed", this._onFavoriteChanged)
  }

  disconnect() {
    document.removeEventListener("tovitu:favorite-changed", this._onFavoriteChanged)
    this.queue.controllers.delete(this)
    releaseQueue(this.petIdValue, this.queue)
  }

  toggle(event) {
    event.preventDefault()
    event.stopPropagation()

    const next = !this.isSaved()
    this.queue.pending = next
    // Update the source of truth optimistically so rapid toggling computes the
    // correct next state (last action wins) while requests are in flight.
    this.savedValue = next
    this.render()
    this.dispatchFavoriteChanged(next)
    this.dispatchCountChange(next ? 1 : -1)
    this.flush()
  }

  isSaved() {
    return this.savedValue
  }

  setSaved(saved) {
    this.savedValue = saved
    this.render()
    this.dispatchFavoriteChanged(saved)
  }

  render() {
    const saved = this.isSaved()
    const button = this.hasButtonTarget ? this.buttonTarget : this.element

    this.swapClasses(this.element, this.controlUnsavedClassValue, this.controlSavedClassValue, saved)
    if (this.hasIconTarget) {
      this.swapClasses(this.iconTarget, this.iconUnsavedClassValue, this.iconSavedClassValue, saved)
    }
    if (this.hasLabelTarget) {
      this.labelTarget.textContent = saved ? this.unsaveLabelValue : this.saveLabelValue
    }
    button.setAttribute("aria-pressed", String(saved))
    button.setAttribute("aria-label", saved ? this.unsaveLabelValue : this.saveLabelValue)
  }

  swapClasses(element, unsavedClasses, savedClasses, saved) {
    const remove = saved ? unsavedClasses : savedClasses
    const add = saved ? savedClasses : unsavedClasses
    element.classList.remove(...remove.split(/\s+/).filter(Boolean))
    element.classList.add(...add.split(/\s+/).filter(Boolean))
  }

  async flush() {
    const queue = this.queue
    if (queue.inFlight || queue.pending === null) return

    const desired = queue.pending
    queue.pending = null
    queue.inFlight = true

    try {
      const response = await fetch(this.element.action, {
        method: desired ? "POST" : "DELETE",
        headers: {
          "Accept": "application/json",
          "X-CSRF-Token": this.csrfToken(),
        },
        credentials: "same-origin",
      })
      if (!response.ok) throw new Error("request failed")

      const data = await response.json()
      // Only commit when no newer action is queued — otherwise the next flush
      // handles the final state and intermediate renders would flicker.
      if (queue.pending === null) {
        this.setSaved(data.saved)
        if (data.milestone) {
          showToast(data.milestone, { tone: "success", dismissLabel: this.dismissLabelValue })
        }
        if (!data.saved) this.removeCardIfPresent()
      }
    } catch {
      // Revert to the state before this request (unless a newer action is
      // queued, in which case the next flush converges to the last action).
      if (queue.pending === null) {
        this.setSaved(!desired)
        this.dispatchCountChange(desired ? -1 : 1)
        showToast(this.errorMessageValue, { tone: "danger", dismissLabel: this.dismissLabelValue })
      }
    } finally {
      queue.inFlight = false
      if (queue.pending !== null) {
        this.flush()
      } else {
        releaseQueue(this.petIdValue, queue)
      }
    }
  }

  // ─────────────────── Saved-pets page removal ───────────────────

  removeCardIfPresent() {
    const card = this.element.closest("[data-favorite-card]")
    if (!card) return

    const finish = () => {
      card.remove()
      this.checkEmptyState()
    }

    if (window.matchMedia("(prefers-reduced-motion: reduce)").matches) {
      finish()
      return
    }

    card.classList.add("favorite-card-exit")
    card.addEventListener("animationend", (event) => {
      if (event.animationName === "favorite-card-exit") finish()
    }, { once: true })
  }

  checkEmptyState() {
    const list = document.getElementById("saved-pets-list")
    const empty = document.getElementById("saved-pets-empty")
    if (!list || !empty) return
    if (!list.querySelector("[data-favorite-card]")) {
      list.classList.add("hidden")
      empty.classList.remove("hidden")
    }
  }

  // ───────────────────────── helpers ─────────────────────────────

  dispatchFavoriteChanged(saved) {
    document.dispatchEvent(new CustomEvent("tovitu:favorite-changed", {
      detail: { petId: this.petIdValue, saved, source: this.element },
    }))
  }

  dispatchCountChange(delta) {
    document.dispatchEvent(new CustomEvent("tovitu:favorites-changed", {
      detail: { petId: this.petIdValue, delta },
    }))
  }

  csrfToken() {
    const meta = document.querySelector('meta[name="csrf-token"]')
    return meta ? meta.content : ""
  }
}