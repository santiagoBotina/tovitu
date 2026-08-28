import { describe, it, expect, beforeEach, afterEach, vi } from "vitest"
import { Application } from "@hotwired/stimulus"
import FavoriteToggleController from "../../../app/javascript/controllers/favorite_toggle_controller"

// The favorite-toggle controller is the signed-in optimistic save/remove. It
// flips the heart instantly, dispatches the request in the background, reverts
// on failure, follows "last action wins" on rapid toggling, and keeps the
// navbar counter in sync via tovitu:favorites-changed events.
describe("FavoriteToggleController", () => {
  let application
  let root

  const flush = () => new Promise((resolve) => setTimeout(resolve, 0))

  function deferred() {
    let resolve, reject
    const promise = new Promise((res, rej) => { resolve = res; reject = rej })
    return { promise, resolve, reject }
  }

  async function mountForm({ saved = false, petId = 1 } = {}) {
    const form = document.createElement("form")
    form.innerHTML = `
      <button type="submit" data-favorite-toggle-target="button" aria-pressed="${saved}">
        <svg data-favorite-toggle-target="icon" class="fill-transparent text-neutral-400"></svg>
        <span data-favorite-toggle-target="label">Save pet</span>
      </button>`
    form.setAttribute("data-controller", "favorite-toggle")
    form.setAttribute("data-favorite-toggle-pet-id-value", String(petId))
    form.setAttribute("data-favorite-toggle-saved-value", String(saved))
    form.setAttribute("data-favorite-toggle-save-label-value", "Save pet")
    form.setAttribute("data-favorite-toggle-unsave-label-value", "Unsave pet")
    form.setAttribute("data-favorite-toggle-error-message-value", "Could not update your favorites")
    form.setAttribute("data-favorite-toggle-dismiss-label-value", "Dismiss")
    form.setAttribute("data-favorite-toggle-control-saved-class-value", "saved-control")
    form.setAttribute("data-favorite-toggle-control-unsaved-class-value", "unsaved-control")
    form.setAttribute("data-favorite-toggle-icon-saved-class-value", "fill-accent-pink heart-saved")
    form.setAttribute("data-favorite-toggle-icon-unsaved-class-value", "fill-transparent text-neutral-400")
    form.setAttribute("data-action", "submit->favorite-toggle#toggle")
    form.action = `/en/pets/${petId}/save`
    root.appendChild(form)
    await flush() // let Stimulus connect before interacting
    return form
  }

  beforeEach(() => {
    localStorage.clear()
    root = document.createElement("div")
    document.body.appendChild(root)
    const flash = document.createElement("div")
    flash.id = "flash-container"
    document.body.appendChild(flash)
    application = Application.start()
    application.register("favorite-toggle", FavoriteToggleController)
    global.fetch = vi.fn()
    window.matchMedia = vi.fn().mockReturnValue({ matches: true })
  })

  afterEach(() => {
    application.stop()
    root.remove()
    document.getElementById("flash-container")?.remove()
    localStorage.clear()
    vi.restoreAllMocks()
  })

  it("toggles optimistically and dispatches the request in the background", async () => {
    const form = await mountForm()
    global.fetch.mockResolvedValue({ ok: true, json: async () => ({ saved: true, milestone: null }) })

    form.querySelector("button").click()
    await flush()

    expect(form.querySelector("button").getAttribute("aria-pressed")).toBe("true")
    expect(form.querySelector('[data-favorite-toggle-target="icon"]').classList.contains("fill-accent-pink")).toBe(true)
    expect(global.fetch).toHaveBeenCalledTimes(1)
    expect(global.fetch.mock.calls[0][1].method).toBe("POST")
    expect(global.fetch.mock.calls[0][0]).toContain("/en/pets/1/save")
  })

  it("unsaves optimistically with a DELETE request", async () => {
    const form = await mountForm({ saved: true })
    global.fetch.mockResolvedValue({ ok: true, json: async () => ({ saved: false }) })

    form.querySelector("button").click()
    await flush()

    expect(form.querySelector("button").getAttribute("aria-pressed")).toBe("false")
    expect(global.fetch.mock.calls[0][1].method).toBe("DELETE")
  })

  it("converges to the last action when toggled rapidly (no race mismatch)", async () => {
    const form = await mountForm()
    const first = deferred()
    const second = deferred()
    global.fetch
      .mockReturnValueOnce(first.promise)
      .mockReturnValueOnce(second.promise)

    const button = form.querySelector("button")
    button.click() // save → POST
    button.click() // unsave → queued

    // First request resolves; the intermediate saved state must NOT render
    // because a newer action is queued.
    first.resolve({ ok: true, json: async () => ({ saved: true, milestone: null }) })
    await flush()

    expect(global.fetch).toHaveBeenCalledTimes(2)
    expect(global.fetch.mock.calls[1][1].method).toBe("DELETE")

    second.resolve({ ok: true, json: async () => ({ saved: false }) })
    await flush()

    expect(button.getAttribute("aria-pressed")).toBe("false")
  })

  it("reverts and notifies in plain language on failure", async () => {
    const form = await mountForm()
    global.fetch.mockResolvedValue({ ok: false })

    form.querySelector("button").click()
    await flush()

    expect(form.querySelector("button").getAttribute("aria-pressed")).toBe("false")
    const toast = document.querySelector("#flash-container .bg-danger")
    expect(toast).toBeTruthy()
    expect(toast.textContent).toContain("Could not update your favorites")
  })

  it("dispatches counter events on optimistic change and on revert", async () => {
    const form = await mountForm()
    const deltas = []
    document.addEventListener("tovitu:favorites-changed", (event) => deltas.push(event.detail.delta))

    global.fetch.mockResolvedValue({ ok: false })
    form.querySelector("button").click()
    await flush()

    expect(deltas).toEqual([ 1, -1 ])
  })

  it("shows the milestone toast when the server reports one", async () => {
    const form = await mountForm()
    global.fetch.mockResolvedValue({ ok: true, json: async () => ({ saved: true, milestone: "First saved pet!" }) })

    form.querySelector("button").click()
    await flush()

    const toast = document.querySelector("#flash-container .bg-success")
    expect(toast).toBeTruthy()
    expect(toast.textContent).toContain("First saved pet!")
  })

  it("removes the card on successful unsave on the saved-pets page", async () => {
    const card = document.createElement("div")
    card.setAttribute("data-favorite-card", "1")
    const form = await mountForm({ saved: true })
    card.appendChild(form)
    root.appendChild(card)

    // Empty-state containers the controller swaps to when the last card leaves.
    const list = document.createElement("div")
    list.id = "saved-pets-list"
    list.appendChild(card)
    const empty = document.createElement("div")
    empty.id = "saved-pets-empty"
    empty.classList.add("hidden")
    root.appendChild(list)
    root.appendChild(empty)

    global.fetch.mockResolvedValue({ ok: true, json: async () => ({ saved: false }) })
    form.querySelector("button").click()
    await flush()

    expect(card.isConnected).toBe(false)
    expect(list.classList.contains("hidden")).toBe(true)
    expect(empty.classList.contains("hidden")).toBe(false)
  })

  it("keeps the card when unsave fails (no silent loss)", async () => {
    const card = document.createElement("div")
    card.setAttribute("data-favorite-card", "1")
    const form = await mountForm({ saved: true })
    card.appendChild(form)
    root.appendChild(card)

    global.fetch.mockResolvedValue({ ok: false })
    form.querySelector("button").click()
    await flush()

    expect(card.isConnected).toBe(true)
    expect(form.querySelector("button").getAttribute("aria-pressed")).toBe("true")
  })

  it("syncs sibling controls for the same pet", async () => {
    const a = await mountForm({ petId: 5 })
    const b = await mountForm({ petId: 5 })
    global.fetch.mockResolvedValue({ ok: true, json: async () => ({ saved: true, milestone: null }) })

    a.querySelector("button").click()
    await flush()

    expect(a.querySelector("button").getAttribute("aria-pressed")).toBe("true")
    expect(b.querySelector("button").getAttribute("aria-pressed")).toBe("true")
  })

  it("shares one last-action-wins queue across sibling controls", async () => {
    const a = await mountForm({ petId: 9 })
    const b = await mountForm({ petId: 9 })
    const first = deferred()
    const second = deferred()
    global.fetch
      .mockReturnValueOnce(first.promise)
      .mockReturnValueOnce(second.promise)

    a.querySelector("button").click() // save via control A
    b.querySelector("button").click() // unsave via control B

    first.resolve({ ok: true, json: async () => ({ saved: true, milestone: null }) })
    await flush()

    // The queued unsave must be dispatched (not lost), and the intermediate
    // saved state must not render.
    expect(global.fetch).toHaveBeenCalledTimes(2)
    expect(global.fetch.mock.calls[1][1].method).toBe("DELETE")

    second.resolve({ ok: true, json: async () => ({ saved: false }) })
    await flush()

    expect(a.querySelector("button").getAttribute("aria-pressed")).toBe("false")
    expect(b.querySelector("button").getAttribute("aria-pressed")).toBe("false")
  })

  it("works after a previous controller disconnects mid-flight (queue not stuck)", async () => {
    const form = await mountForm({ petId: 42 })
    const pending = deferred()
    global.fetch.mockReturnValueOnce(pending.promise)

    form.querySelector("button").click() // starts a request
    form.remove() // disconnect mid-flight
    await flush()

    // The in-flight request settles after the controller is gone.
    pending.resolve({ ok: true, json: async () => ({ saved: true, milestone: null }) })
    await flush()

    // A fresh controller for the same pet works normally (no stuck queue).
    const form2 = await mountForm({ petId: 42 })
    global.fetch.mockResolvedValue({ ok: true, json: async () => ({ saved: true, milestone: null }) })
    form2.querySelector("button").click()
    await flush()

    expect(global.fetch).toHaveBeenCalledTimes(2)
    expect(form2.querySelector("button").getAttribute("aria-pressed")).toBe("true")
  })
})