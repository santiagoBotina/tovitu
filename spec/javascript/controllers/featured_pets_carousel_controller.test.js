import { describe, it, expect, beforeEach, afterEach, vi } from "vitest"
import { Application } from "@hotwired/stimulus"
import FeaturedPetsCarouselController from "../../../app/javascript/controllers/featured_pets_carousel_controller"

// The featured_pets_carousel controller drives the landing-page pet strip:
// prev/next arrows scroll by one "card + gap" step, the buttons reflect
// reachability (disabled at the ends), reduced motion switches to instant
// scroll, and a missing strip (empty state) is a no-op.
describe("FeaturedPetsCarouselController", () => {
  let application
  let root
  let originalGetComputedStyle

  // Stimulus connects controllers through a MutationObserver, which fires
  // asynchronously — give it a tick before asserting connected behavior.
  const flush = () => new Promise((resolve) => setTimeout(resolve, 0))

  function mount({ scrollWidth = 2000, clientWidth = 800, scrollLeft = 0, cardWidth = 288, gap = "20px" } = {}) {
    root = document.createElement("div")
    root.innerHTML = `
      <div data-controller="featured-pets-carousel">
        <button type="button" data-featured-pets-carousel-target="prevButton"
                data-action="click->featured-pets-carousel#previous"></button>
        <button type="button" data-featured-pets-carousel-target="nextButton"
                data-action="click->featured-pets-carousel#next"></button>
        <div data-featured-pets-carousel-target="strip" class="flex gap-5 overflow-x-auto">
          <div role="listitem" class="w-72"></div>
          <div role="listitem" class="w-72"></div>
          <div role="listitem" class="w-72"></div>
        </div>
      </div>`
    const strip = root.querySelector('[data-featured-pets-carousel-target="strip"]')
    const firstCard = strip.querySelector("[role='listitem']")
    Object.defineProperty(strip, "scrollWidth", { value: scrollWidth, configurable: true })
    Object.defineProperty(strip, "clientWidth", { value: clientWidth, configurable: true })
    Object.defineProperty(strip, "scrollLeft", { value: scrollLeft, writable: true, configurable: true })
    Object.defineProperty(firstCard, "clientWidth", { value: cardWidth, configurable: true })
    strip.scrollBy = vi.fn()

    // jsdom does no layout, so columnGap is empty — stub it to the flex gap.
    vi.spyOn(window, "getComputedStyle").mockImplementation((el) => {
      if (el === strip) return { columnGap: gap }
      return originalGetComputedStyle(el)
    })

    document.body.appendChild(root)
    return root
  }

  const strip = () => root.querySelector('[data-featured-pets-carousel-target="strip"]')
  const prevButton = () => root.querySelector('[data-featured-pets-carousel-target="prevButton"]')
  const nextButton = () => root.querySelector('[data-featured-pets-carousel-target="nextButton"]')

  beforeEach(() => {
    originalGetComputedStyle = window.getComputedStyle
    // jsdom does not implement matchMedia; the controller reads it on connect.
    window.matchMedia = vi.fn().mockReturnValue({ matches: false })
    application = Application.start()
    application.register("featured-pets-carousel", FeaturedPetsCarouselController)
  })

  afterEach(() => {
    application.stop()
    root?.remove()
    vi.restoreAllMocks()
  })

  it("scrolls the strip by one card + gap step on next", async () => {
    mount()
    await flush()

    nextButton().click()

    expect(strip().scrollBy).toHaveBeenCalledWith({ left: 308, behavior: "smooth" })
  })

  it("scrolls the strip backwards by one card + gap step on previous", async () => {
    mount({ scrollLeft: 616 })
    await flush()

    prevButton().click()

    expect(strip().scrollBy).toHaveBeenCalledWith({ left: -308, behavior: "smooth" })
  })

  it("uses instant scroll when the user prefers reduced motion", async () => {
    window.matchMedia.mockReturnValue({ matches: true })
    mount()
    await flush()

    nextButton().click()

    expect(strip().scrollBy).toHaveBeenCalledWith({ left: 308, behavior: "auto" })
  })

  it("disables prev at the start and next at the end", async () => {
    mount()
    await flush()

    expect(prevButton().disabled).toBe(true)
    expect(nextButton().disabled).toBe(false)

    strip().scrollLeft = 1200
    strip().dispatchEvent(new Event("scroll"))

    expect(prevButton().disabled).toBe(false)
    expect(nextButton().disabled).toBe(true)
  })

  it("disables both arrows when the strip cannot scroll (few cards)", async () => {
    mount({ scrollWidth: 800, clientWidth: 800 })
    await flush()

    expect(prevButton().disabled).toBe(true)
    expect(nextButton().disabled).toBe(true)
  })

  it("is a no-op when there is no strip (empty featured-pets state)", async () => {
    root = document.createElement("div")
    root.innerHTML = `<div data-controller="featured-pets-carousel"></div>`
    document.body.appendChild(root)
    await flush()

    expect(root.querySelector('[data-featured-pets-carousel-target="strip"]')).toBeNull()
  })
})