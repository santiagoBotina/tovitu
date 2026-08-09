import { describe, it, expect, beforeEach, afterEach } from "vitest"
import { Application } from "@hotwired/stimulus"
import PetInterestController from "../../../app/javascript/controllers/pet_interest_controller"

// The pet-interest controller is the signed-out "paw it" bookmark. It stores
// pet ids in localStorage, updates the icon + label + aria state on toggle,
// and keeps every control for the same pet in sync via the
// `tovitu:interest-changed` event (heart on the profile hero + labeled button).
describe("PetInterestController", () => {
  let application
  let root

  const flush = () => new Promise((resolve) => setTimeout(resolve, 0))

  async function mountButton(id = 1) {
    const btn = document.createElement("button")
    btn.innerHTML = `
      <svg data-pet-interest-target="icon" class="fill-transparent text-neutral-400"></svg>
      <span data-pet-interest-target="label">Save pet</span>`
    btn.setAttribute("data-controller", "pet-interest")
    btn.setAttribute("data-pet-interest-id-value", String(id))
    btn.setAttribute("data-pet-interest-save-label-value", "Save pet")
    btn.setAttribute("data-pet-interest-unsave-label-value", "Unsave pet")
    btn.setAttribute("data-action", "click->pet-interest#toggle")
    root.appendChild(btn)
    await flush() // let Stimulus connect before interacting
    return btn
  }

  beforeEach(() => {
    localStorage.clear()
    root = document.createElement("div")
    document.body.appendChild(root)
    application = Application.start()
    application.register("pet-interest", PetInterestController)
  })

  afterEach(() => {
    application.stop()
    root.remove()
    localStorage.clear()
  })

  it("saves and unsaves a pet on click, updating label, aria, and icon", async () => {
    const btn = await mountButton(7)

    expect(btn.getAttribute("aria-pressed")).toBe("false")
    expect(btn.querySelector('[data-pet-interest-target="label"]').textContent).toBe("Save pet")

    btn.click()
    expect(btn.getAttribute("aria-pressed")).toBe("true")
    expect(btn.querySelector('[data-pet-interest-target="label"]').textContent).toBe("Unsave pet")
    expect(btn.querySelector('[data-pet-interest-target="icon"]').classList.contains("fill-accent-pink")).toBe(true)

    btn.click()
    expect(btn.getAttribute("aria-pressed")).toBe("false")
    expect(btn.querySelector('[data-pet-interest-target="label"]').textContent).toBe("Save pet")
  })

  it("syncs sibling controls for the same pet", async () => {
    const a = await mountButton(3)
    const b = await mountButton(3)

    a.click()
    expect(a.getAttribute("aria-pressed")).toBe("true")
    expect(b.getAttribute("aria-pressed")).toBe("true")
    expect(b.querySelector('[data-pet-interest-target="label"]').textContent).toBe("Unsave pet")

    // Un-saving through the sibling updates both back.
    b.click()
    expect(a.getAttribute("aria-pressed")).toBe("false")
    expect(b.getAttribute("aria-pressed")).toBe("false")
  })

  it("does not sync controls for a different pet", async () => {
    const a = await mountButton(1)
    const b = await mountButton(2)

    a.click()

    expect(b.getAttribute("aria-pressed")).toBe("false")
  })
})
