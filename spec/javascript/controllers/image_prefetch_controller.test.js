import { describe, it, expect, beforeEach, afterEach, vi } from "vitest"
import { Application } from "@hotwired/stimulus"
import ImagePrefetchController from "../../../app/javascript/controllers/image_prefetch_controller"

// The image_prefetch controller warms the browser cache for a profile's hero
// image on hover. Prefetch is debounced (150ms) and cancelled on mouseleave so
// a quick pass over a grid of cards does not trigger a burst of large
// downloads; a given controller never prefetches the same URL twice.
describe("ImagePrefetchController", () => {
  let application
  let root
  let imageInstances

  const flush = () => new Promise((resolve) => setTimeout(resolve, 0))

  async function mount(url) {
    root = document.createElement("div")
    root.innerHTML = `
      <div data-controller="image-prefetch"
           data-image-prefetch-url-value="${url}"
           data-action="mouseenter->image-prefetch#prefetch mouseleave->image-prefetch#cancel">
        <a href="/pets/1">Pet</a>
      </div>`
    document.body.appendChild(root)
    await flush() // let Stimulus connect before we control the clock
    return root.querySelector("[data-controller='image-prefetch']")
  }

  beforeEach(() => {
    imageInstances = []
    vi.stubGlobal("Image", class {
      constructor() {
        this.src = ""
        this.decoding = ""
        imageInstances.push(this)
      }
    })
    application = Application.start()
    application.register("image-prefetch", ImagePrefetchController)
  })

  afterEach(() => {
    application.stop()
    root?.remove()
    vi.useRealTimers()
    vi.unstubAllGlobals()
  })

  it("prefetches the url after the debounce delay on a persistent hover", async () => {
    const el = await mount("/rails/active_storage/representations/pet.jpg")
    vi.useFakeTimers()

    el.dispatchEvent(new MouseEvent("mouseenter"))

    // Debounce has not elapsed yet.
    expect(imageInstances).toHaveLength(0)

    vi.advanceTimersByTime(160)

    expect(imageInstances).toHaveLength(1)
    expect(imageInstances[0].src).toBe("/rails/active_storage/representations/pet.jpg")
    expect(imageInstances[0].decoding).toBe("async")
  })

  it("does not prefetch an empty url", async () => {
    const el = await mount("")
    vi.useFakeTimers()

    el.dispatchEvent(new MouseEvent("mouseenter"))
    vi.advanceTimersByTime(200)

    expect(imageInstances).toHaveLength(0)
  })

  it("only prefetches once per controller", async () => {
    const el = await mount("/a.jpg")
    vi.useFakeTimers()

    el.dispatchEvent(new MouseEvent("mouseenter"))
    vi.advanceTimersByTime(160)
    el.dispatchEvent(new MouseEvent("mouseenter"))
    vi.advanceTimersByTime(200)

    expect(imageInstances).toHaveLength(1)
  })

  it("cancels the prefetch when the mouse leaves before the debounce fires", async () => {
    const el = await mount("/a.jpg")
    vi.useFakeTimers()

    el.dispatchEvent(new MouseEvent("mouseenter"))
    el.dispatchEvent(new MouseEvent("mouseleave"))
    vi.advanceTimersByTime(200)

    expect(imageInstances).toHaveLength(0)
  })
})
