import { describe, it, expect, beforeEach, afterEach, vi } from "vitest"
import { Application } from "@hotwired/stimulus"
import PetImportController from "../../../app/javascript/controllers/pet_import_controller"

// The pet-import controller polls the server-driven import status while a
// background batch pet import is pending and applies the returned turbo_stream.
// It stops once the import completes OR fails (both terminal states).
describe("PetImportController", () => {
  let application
  let root

  function setNotice(status) {
    const notice = document.createElement("div")
    notice.id = "pet-import-notice"
    notice.dataset.petImportStatus = status
    document.body.appendChild(notice)
    return notice
  }

  beforeEach(() => {
    vi.useFakeTimers()
    application = Application.start()
    application.register("pet-import", PetImportController)
    root = document.createElement("div")
    root.setAttribute("data-controller", "pet-import")
    root.setAttribute("data-pet-import-status-url-value", "/en/shelter/pet_imports/1/status")
    root.setAttribute("data-pet-import-interval-value", "100")
    document.body.appendChild(root)
    global.fetch = vi.fn()
    global.Turbo = { renderStreamMessage: vi.fn() }
  })

  afterEach(() => {
    application.stop()
    root.remove()
    document.getElementById("pet-import-notice")?.remove()
    vi.useRealTimers()
    vi.restoreAllMocks()
  })

  it("polls while the notice is pending", async () => {
    setNotice("pending")
    global.fetch.mockResolvedValue({ ok: true, text: async () => "" })

    await vi.advanceTimersByTimeAsync(100)
    expect(global.fetch).toHaveBeenCalledTimes(1)

    await vi.advanceTimersByTimeAsync(100)
    expect(global.fetch).toHaveBeenCalledTimes(2)
  })

  it("stops polling once the import completes", async () => {
    const notice = setNotice("pending")
    global.fetch.mockResolvedValue({ ok: true, text: async () => "" })

    await vi.advanceTimersByTimeAsync(100)
    expect(global.fetch).toHaveBeenCalledTimes(1)

    notice.dataset.petImportStatus = "completed"
    await vi.advanceTimersByTimeAsync(300)
    expect(global.fetch).toHaveBeenCalledTimes(1)
  })

  it("stops polling when the import fails", async () => {
    const notice = setNotice("pending")
    global.fetch.mockResolvedValue({ ok: true, text: async () => "" })

    await vi.advanceTimersByTimeAsync(100)
    expect(global.fetch).toHaveBeenCalledTimes(1)

    notice.dataset.petImportStatus = "failed"
    await vi.advanceTimersByTimeAsync(300)
    expect(global.fetch).toHaveBeenCalledTimes(1)
  })

  it("does not fetch when no notice exists and nothing is pending", async () => {
    global.fetch.mockResolvedValue({ ok: true, text: async () => "" })

    await vi.advanceTimersByTimeAsync(300)
    expect(global.fetch).not.toHaveBeenCalled()
  })

  it("applies the returned turbo_stream", async () => {
    setNotice("pending")
    global.fetch.mockResolvedValue({ ok: true, text: async () => "<turbo-stream action='replace' target='x'></turbo-stream>" })

    await vi.advanceTimersByTimeAsync(100)
    expect(global.Turbo.renderStreamMessage).toHaveBeenCalledWith("<turbo-stream action='replace' target='x'></turbo-stream>")
  })

  it("stops polling after the tick cap", async () => {
    setNotice("pending")
    root.setAttribute("data-pet-import-max-ticks-value", "2")
    global.fetch.mockResolvedValue({ ok: true, text: async () => "" })

    await vi.advanceTimersByTimeAsync(100) // tick 1 → fetch
    await vi.advanceTimersByTimeAsync(100) // tick 2 → fetch
    expect(global.fetch).toHaveBeenCalledTimes(2)

    await vi.advanceTimersByTimeAsync(300) // tick 3 exceeds cap → stop
    expect(global.fetch).toHaveBeenCalledTimes(2)
  })
})