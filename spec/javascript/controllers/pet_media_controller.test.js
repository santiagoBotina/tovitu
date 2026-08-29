import { describe, it, expect, beforeEach, afterEach, vi } from "vitest"
import { Application } from "@hotwired/stimulus"
import PetMediaController from "../../../app/javascript/controllers/pet_media_controller"

// The pet-media controller auto-submits the multi-file upload when files are
// chosen and shows how many are selected. The grid + toasts come back via
// turbo_stream from the photo controller.
describe("PetMediaController", () => {
  let application
  let root

  beforeEach(() => {
    application = Application.start()
    application.register("pet-media", PetMediaController)
    root = document.createElement("div")
    root.setAttribute("data-controller", "pet-media")
    root.innerHTML = `
      <form data-pet-media-target="uploadForm">
        <input type="file" name="files[]" multiple data-pet-media-target="files" data-action="change->pet-media#submitFiles">
        <p data-pet-media-target="count" data-count-template="%{count} selected" class="hidden"></p>
      </form>
    `
    document.body.appendChild(root)
  })

  afterEach(() => {
    application.stop()
    root.remove()
    vi.restoreAllMocks()
  })

  it("submits the upload form when files are chosen", () => {
    const form = root.querySelector("form")
    const submit = vi.fn()
    form.requestSubmit = submit

    const files = root.querySelector("input[type=file]")
    Object.defineProperty(files, "files", { value: [ {}, {} ], configurable: true })
    files.dispatchEvent(new Event("change"))

    expect(submit).toHaveBeenCalledTimes(1)
  })

  it("shows the number of selected files", () => {
    const files = root.querySelector("input[type=file]")
    const count = root.querySelector("[data-pet-media-target=count]")
    Object.defineProperty(files, "files", { value: [ {}, {}, {} ], configurable: true })
    files.dispatchEvent(new Event("change"))

    expect(count.classList.contains("hidden")).toBe(false)
    expect(count.textContent).toBe("3 selected")
  })

  it("does not submit when no files are chosen", () => {
    const form = root.querySelector("form")
    const submit = vi.fn()
    form.requestSubmit = submit

    const files = root.querySelector("input[type=file]")
    Object.defineProperty(files, "files", { value: [], configurable: true })
    files.dispatchEvent(new Event("change"))

    expect(submit).not.toHaveBeenCalled()
  })
})