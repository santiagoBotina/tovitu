import { describe, it, expect, beforeEach, afterEach } from "vitest"
import { Application } from "@hotwired/stimulus"
import ImageLoaderController from "../../../app/javascript/controllers/image_loader_controller"

// The image_loader controller reveals an <img> once it has loaded: a cached
// image (complete + naturalWidth) is revealed on connect, an image that loads
// later is revealed on the `load` event, and an error drops the skeleton so
// the container's fallback background shows.
describe("ImageLoaderController", () => {
  let application
  let root

  // Stimulus connects controllers through a MutationObserver, which fires
  // asynchronously — give it a tick before asserting connected behavior.
  const flush = () => new Promise((resolve) => setTimeout(resolve, 0))

  function mount({ complete = false, naturalWidth = 0 } = {}) {
    root = document.createElement("div")
    root.innerHTML = `
      <div data-controller="image-loader">
        <div data-image-loader-target="skeleton" class="img-skeleton" aria-hidden="true"></div>
        <img data-image-loader-target="image"
             data-action="load->image-loader#loaded error->image-loader#failed"
             class="opacity-0">
      </div>`
    const img = root.querySelector("img")
    Object.defineProperty(img, "complete", { value: complete, configurable: true })
    Object.defineProperty(img, "naturalWidth", { value: naturalWidth, configurable: true })
    document.body.appendChild(root)
    return root
  }

  const skeleton = () => root.querySelector('[data-image-loader-target="skeleton"]')
  const img = () => root.querySelector("img")

  beforeEach(() => {
    application = Application.start()
    application.register("image-loader", ImageLoaderController)
  })

  afterEach(() => {
    application.stop()
    root?.remove()
  })

  it("keeps the skeleton while the image is still loading", async () => {
    mount() // not complete, no naturalWidth
    await flush()
    expect(img().classList.contains("opacity-0")).toBe(true)
    expect(skeleton()).not.toBeNull()
  })

  it("reveals an already-cached image immediately on connect", async () => {
    mount({ complete: true, naturalWidth: 500 })
    await flush()
    expect(img().classList.contains("opacity-0")).toBe(false)
    expect(skeleton()).toBeNull()
  })

  it("reveals the image when it finishes loading", async () => {
    mount()
    await flush()
    expect(skeleton()).not.toBeNull()

    img().dispatchEvent(new Event("load"))

    expect(img().classList.contains("opacity-0")).toBe(false)
    expect(skeleton()).toBeNull()
  })

  it("removes the skeleton on load error so the fallback shows", async () => {
    mount()
    await flush()
    img().dispatchEvent(new Event("error"))

    expect(skeleton()).toBeNull()
  })
})
