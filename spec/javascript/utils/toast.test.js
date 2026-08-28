import { describe, it, expect, beforeEach, afterEach } from "vitest"
import { showToast } from "../../../app/javascript/utils/toast"

// The client-side toast mirrors shared/_flash styling so optimistic actions
// can surface feedback without a round trip. It appends to #flash-container
// and auto-dismisses via the dismiss controller (not exercised here).
describe("showToast", () => {
  let container

  beforeEach(() => {
    container = document.createElement("div")
    container.id = "flash-container"
    document.body.appendChild(container)
  })

  afterEach(() => {
    container.remove()
  })

  it("appends a toast with the message", () => {
    showToast("Hello there", { tone: "success" })

    const toast = container.querySelector(".bg-success")
    expect(toast).toBeTruthy()
    expect(toast.textContent).toContain("Hello there")
    expect(toast.getAttribute("role")).toBe("alert")
  })

  it("uses the danger tone by default", () => {
    showToast("Oops")

    expect(container.querySelector(".bg-danger")).toBeTruthy()
    expect(container.querySelector(".bg-success")).toBeNull()
  })

  it("uses the localized dismiss label", () => {
    showToast("Oops", { dismissLabel: "Descartar" })

    const button = container.querySelector("button")
    expect(button.getAttribute("aria-label")).toBe("Descartar")
  })

  it("does nothing without a message", () => {
    showToast("")

    expect(container.children.length).toBe(0)
  })

  it("does nothing when the flash container is missing", () => {
    container.remove()

    expect(() => showToast("Hello")).not.toThrow()
  })
})