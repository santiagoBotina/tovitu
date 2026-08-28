import { describe, it, expect, beforeEach, afterEach, vi } from "vitest"
import { Application } from "@hotwired/stimulus"
import FavoritesImportController from "../../../app/javascript/controllers/favorites_import_controller"

// The favorites-import controller polls the server-driven import status while
// a background favorites import is pending and applies the returned
// turbo_stream. It stops once the import completes and waits (without
// fetching) while the notice is failed.
describe("FavoritesImportController", () => {
  let application
  let root

  const flush = () => vi.advanceTimersByTimeAsync(0)

  function setNotice(status) {
    const notice = document.createElement("div")
    notice.id = "favorites-import-notice"
    notice.dataset.favoritesImportStatus = status
    document.body.appendChild(notice)
    return notice
  }

  beforeEach(() => {
    vi.useFakeTimers()
    application = Application.start()
    application.register("favorites-import", FavoritesImportController)
    root = document.createElement("div")
    root.setAttribute("data-controller", "favorites-import")
    root.setAttribute("data-favorites-import-status-url-value", "/en/saved_pets/import_status")
    root.setAttribute("data-favorites-import-interval-value", "100")
    document.body.appendChild(root)
    global.fetch = vi.fn()
    global.Turbo = { renderStreamMessage: vi.fn() }
  })

  afterEach(() => {
    application.stop()
    root.remove()
    document.getElementById("favorites-import-notice")?.remove()
    vi.useRealTimers()
    vi.restoreAllMocks()
  })

  it("polls while the notice is pending", async () => {
    setNotice("pending")
    global.fetch.mockResolvedValue({ ok: true, text: async () => "" })
    await flush() // let Stimulus connect

    await vi.advanceTimersByTimeAsync(100)
    expect(global.fetch).toHaveBeenCalledTimes(1)

    await vi.advanceTimersByTimeAsync(100)
    expect(global.fetch).toHaveBeenCalledTimes(2)
  })

  it("stops polling once the import completes", async () => {
    const notice = setNotice("pending")
    global.fetch.mockResolvedValue({ ok: true, text: async () => "" })
    await flush()

    await vi.advanceTimersByTimeAsync(100)
    expect(global.fetch).toHaveBeenCalledTimes(1)

    notice.dataset.favoritesImportStatus = "completed"
    await vi.advanceTimersByTimeAsync(300)
    expect(global.fetch).toHaveBeenCalledTimes(1)
  })

  it("does not fetch while the notice is failed", async () => {
    setNotice("failed")
    await flush()

    await vi.advanceTimersByTimeAsync(300)
    expect(global.fetch).not.toHaveBeenCalled()
  })

  it("resumes polling after a retry flips the notice back to pending", async () => {
    const notice = setNotice("failed")
    global.fetch.mockResolvedValue({ ok: true, text: async () => "" })
    await flush()

    await vi.advanceTimersByTimeAsync(200)
    expect(global.fetch).not.toHaveBeenCalled()

    notice.dataset.favoritesImportStatus = "pending"
    await vi.advanceTimersByTimeAsync(100)
    expect(global.fetch).toHaveBeenCalledTimes(1)
  })

  it("applies the returned turbo_stream", async () => {
    setNotice("pending")
    global.fetch.mockResolvedValue({ ok: true, text: async () => "<turbo-stream action='replace' target='x'></turbo-stream>" })
    await flush()

    await vi.advanceTimersByTimeAsync(100)
    expect(global.Turbo.renderStreamMessage).toHaveBeenCalledWith("<turbo-stream action='replace' target='x'></turbo-stream>")
  })

  it("polls for a signed-in user with local interests even before the notice appears", async () => {
    root.setAttribute("data-favorites-import-signed-in-value", "true")
    localStorage.setItem("tovitu:interests", JSON.stringify([ 1, 2 ]))
    global.fetch.mockResolvedValue({ ok: true, text: async () => "" })
    await flush()

    await vi.advanceTimersByTimeAsync(100)
    expect(global.fetch).toHaveBeenCalledTimes(1)
  })

  it("does not poll for a signed-in user with no notice and no local interests", async () => {
    root.setAttribute("data-favorites-import-signed-in-value", "true")
    localStorage.clear()
    global.fetch.mockResolvedValue({ ok: true, text: async () => "" })
    await flush()

    await vi.advanceTimersByTimeAsync(300)
    expect(global.fetch).not.toHaveBeenCalled()
  })

  it("does not poll for a signed-out user with no notice", async () => {
    root.setAttribute("data-favorites-import-signed-in-value", "false")
    localStorage.setItem("tovitu:interests", JSON.stringify([ 1 ]))
    global.fetch.mockResolvedValue({ ok: true, text: async () => "" })
    await flush()

    await vi.advanceTimersByTimeAsync(300)
    expect(global.fetch).not.toHaveBeenCalled()
  })

  it("stops polling after the cap when no notice ever appears", async () => {
    root.setAttribute("data-favorites-import-signed-in-value", "true")
    root.setAttribute("data-favorites-import-max-no-notice-ticks-value", "2")
    localStorage.setItem("tovitu:interests", JSON.stringify([ 1 ]))
    global.fetch.mockResolvedValue({ ok: true, text: async () => "" })
    await flush()

    await vi.advanceTimersByTimeAsync(100) // tick 1 → fetch
    await vi.advanceTimersByTimeAsync(100) // tick 2 → fetch
    expect(global.fetch).toHaveBeenCalledTimes(2)

    await vi.advanceTimersByTimeAsync(300) // tick 3 exceeds cap → stop
    expect(global.fetch).toHaveBeenCalledTimes(2)
  })

  it("resets the no-notice cap once a pending notice appears", async () => {
    root.setAttribute("data-favorites-import-signed-in-value", "true")
    root.setAttribute("data-favorites-import-max-no-notice-ticks-value", "2")
    localStorage.setItem("tovitu:interests", JSON.stringify([ 1 ]))
    global.fetch.mockResolvedValue({ ok: true, text: async () => "" })
    await flush()

    await vi.advanceTimersByTimeAsync(100) // tick 1 → fetch (no notice yet)
    const notice = setNotice("pending")
    await vi.advanceTimersByTimeAsync(100) // tick 2 → pending → fetch, cap reset
    await vi.advanceTimersByTimeAsync(100) // tick 3 → pending → fetch (cap was reset)
    expect(global.fetch).toHaveBeenCalledTimes(3)
    notice.remove()
  })
})