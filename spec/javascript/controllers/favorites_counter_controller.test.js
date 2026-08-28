import { describe, it, expect, beforeEach, afterEach } from "vitest"
import { Application } from "@hotwired/stimulus"
import FavoritesCounterController from "../../../app/javascript/controllers/favorites_counter_controller"

// The favorites-counter controller keeps the navbar saved-pets badge in sync
// with optimistic save/remove actions via tovitu:favorites-changed events.
describe("FavoritesCounterController", () => {
  let application
  let badge

  beforeEach(() => {
    application = Application.start()
    application.register("favorites-counter", FavoritesCounterController)
    badge = document.createElement("span")
    badge.setAttribute("data-controller", "favorites-counter")
    badge.setAttribute("data-favorites-counter-count-value", "2")
    document.body.appendChild(badge)
  })

  afterEach(() => {
    application.stop()
    badge.remove()
  })

  it("renders the initial count", () => {
    expect(badge.textContent).toBe("2")
    expect(badge.classList.contains("hidden")).toBe(false)
  })

  it("increments on save events", () => {
    document.dispatchEvent(new CustomEvent("tovitu:favorites-changed", { detail: { petId: 1, delta: 1 } }))
    expect(badge.textContent).toBe("3")
  })

  it("decrements on remove events", () => {
    document.dispatchEvent(new CustomEvent("tovitu:favorites-changed", { detail: { petId: 1, delta: -1 } }))
    expect(badge.textContent).toBe("1")
  })

  it("hides the badge when the count reaches zero", () => {
    document.dispatchEvent(new CustomEvent("tovitu:favorites-changed", { detail: { petId: 1, delta: -1 } }))
    document.dispatchEvent(new CustomEvent("tovitu:favorites-changed", { detail: { petId: 2, delta: -1 } }))
    expect(badge.textContent).toBe("0")
    expect(badge.classList.contains("hidden")).toBe(true)
  })

  it("never goes below zero", () => {
    document.dispatchEvent(new CustomEvent("tovitu:favorites-changed", { detail: { petId: 1, delta: -5 } }))
    expect(badge.textContent).toBe("0")
  })
})