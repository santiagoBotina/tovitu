import { describe, it, expect, beforeEach, afterEach, vi } from "vitest"
import { Application } from "@hotwired/stimulus"
import InterestImportController from "../../../app/javascript/controllers/interest_import_controller"

// The interest-import controller auto-imports localStorage interests after
// authentication: it POSTs them to the import endpoint, renders the returned
// turbo_stream (the "Importing your favorites…" toast), and clears the local
// copy only after the server accepts them.
describe("InterestImportController", () => {
  let application
  let root

  const flush = () => new Promise((resolve) => setTimeout(resolve, 0))

  function mount() {
    root = document.createElement("div")
    root.setAttribute("data-controller", "interest-import")
    root.setAttribute("data-interest-import-import-url-value", "/en/saved_pets/import")
    document.body.appendChild(root)
    return root
  }

  beforeEach(() => {
    localStorage.clear()
    application = Application.start()
    application.register("interest-import", InterestImportController)
    global.fetch = vi.fn()
    global.Turbo = { renderStreamMessage: vi.fn() }
  })

  afterEach(() => {
    application.stop()
    root?.remove()
    localStorage.clear()
    vi.restoreAllMocks()
  })

  it("does nothing when there are no local interests", async () => {
    mount()
    await flush()

    expect(global.fetch).not.toHaveBeenCalled()
  })

  it("POSTs local interests and clears them on success", async () => {
    localStorage.setItem("tovitu:interests", JSON.stringify([ 3, 7 ]))
    global.fetch.mockResolvedValue({ ok: true, text: async () => "<turbo-stream></turbo-stream>" })

    mount()
    await flush()

    expect(global.fetch).toHaveBeenCalledTimes(1)
    expect(global.fetch.mock.calls[0][0]).toContain("/en/saved_pets/import")
    expect(global.fetch.mock.calls[0][1].method).toBe("POST")
    expect(global.Turbo.renderStreamMessage).toHaveBeenCalledWith("<turbo-stream></turbo-stream>")
    expect(localStorage.getItem("tovitu:interests")).toBeNull()
  })

  it("keeps the local copy when the request fails (retry on next load)", async () => {
    localStorage.setItem("tovitu:interests", JSON.stringify([ 3 ]))
    global.fetch.mockResolvedValue({ ok: false })

    mount()
    await flush()

    expect(localStorage.getItem("tovitu:interests")).toBe(JSON.stringify([ 3 ]))
  })

  it("keeps the local copy when the network throws", async () => {
    localStorage.setItem("tovitu:interests", JSON.stringify([ 3 ]))
    global.fetch.mockRejectedValue(new Error("network down"))

    mount()
    await flush()

    expect(localStorage.getItem("tovitu:interests")).toBe(JSON.stringify([ 3 ]))
  })
})