import { describe, it, expect, beforeEach, afterEach, vi } from "vitest"
import { Application } from "@hotwired/stimulus"
import CityAutocompleteController from "../../../app/javascript/controllers/city_autocomplete_controller"

// The city autocomplete combobox backs the manual location entry. As the user
// types it filters a bundled US city list, auto-fills region/country on
// selection, and follows the ARIA combobox + listbox keyboard pattern.
describe("CityAutocompleteController", () => {
  let application
  let root

  const flush = () => new Promise((resolve) => setTimeout(resolve, 0))

  async function mount({ value = "" } = {}) {
    const el = document.createElement("div")
    el.id = "city-autocomplete-test"
    el.setAttribute("data-controller", "city-autocomplete")
    el.setAttribute("data-city-autocomplete-country-value", "United States")
    el.innerHTML = `
      <input data-city-autocomplete-target="city" value="${value}" role="combobox" aria-expanded="false"
             data-action="input->city-autocomplete#filter keydown->city-autocomplete#onKeydown">
      <input data-city-autocomplete-target="region">
      <input data-city-autocomplete-target="country">
      <ul data-city-autocomplete-target="listbox" role="listbox" class="hidden"></ul>`
    root.appendChild(el)
    await flush()
    return el
  }

  beforeEach(() => {
    root = document.createElement("div")
    document.body.appendChild(root)
    window.matchMedia = vi.fn().mockReturnValue({ matches: true })
    application = Application.start()
    application.register("city-autocomplete", CityAutocompleteController)
  })

  afterEach(() => {
    application.stop()
    root.remove()
    vi.restoreAllMocks()
  })

  function dispatch(el, event, value) {
    el.value = value
    el.dispatchEvent(new Event(event, { bubbles: true }))
  }

  it("renders matching city suggestions as the user types", async () => {
    const el = await mount()
    const input = el.querySelector('[data-city-autocomplete-target="city"]')
    const listbox = el.querySelector('[data-city-autocomplete-target="listbox"]')

    dispatch(input, "input", "Aus")
    await flush()

    expect(input.getAttribute("aria-expanded")).toBe("true")
    const options = el.querySelectorAll('[data-city-autocomplete-target="option"]')
    expect(options.length).toBeGreaterThan(0)
    expect([...options].map((o) => o.textContent)).toContain("Austin, TX")
  })

  it("selecting a suggestion fills city, region, and country", async () => {
    const el = await mount()
    const input = el.querySelector('[data-city-autocomplete-target="city"]')
    const region = el.querySelector('[data-city-autocomplete-target="region"]')
    const country = el.querySelector('[data-city-autocomplete-target="country"]')

    dispatch(input, "input", "Aus")
    await flush()

    const austin = [...el.querySelectorAll('[data-city-autocomplete-target="option"]')]
      .find((o) => o.textContent.includes("Austin"))
    austin.dispatchEvent(new MouseEvent("mousedown", { bubbles: true }))
    await flush()

    expect(input.value).toBe("Austin")
    expect(region.value).toBe("TX")
    expect(country.value).toBe("United States")
    expect(listbox().classList.contains("hidden")).toBe(true)
  })

  it("closes the listbox and clears active state on Escape", async () => {
    const el = await mount()
    const input = el.querySelector('[data-city-autocomplete-target="city"]')

    dispatch(input, "input", "Dal")
    await flush()
    expect(input.getAttribute("aria-expanded")).toBe("true")

    input.dispatchEvent(new KeyboardEvent("keydown", { key: "Escape", bubbles: true }))
    await flush()

    expect(input.getAttribute("aria-expanded")).toBe("false")
    expect(listbox().classList.contains("hidden")).toBe(true)
  })

  it("keeps a manually typed (unmatched) city valid and closes the list", async () => {
    const el = await mount()
    const input = el.querySelector('[data-city-autocomplete-target="city"]')

    dispatch(input, "input", "Zzznope")
    await flush()

    expect(input.getAttribute("aria-expanded")).toBe("false")
    expect(listbox().querySelectorAll('[data-city-autocomplete-target="option"]').length).toBe(0)
  })

  it("closes on click outside", async () => {
    const el = await mount()
    const input = el.querySelector('[data-city-autocomplete-target="city"]')

    dispatch(input, "input", "Aus")
    await flush()
    expect(input.getAttribute("aria-expanded")).toBe("true")

    document.body.dispatchEvent(new MouseEvent("click", { bubbles: true }))
    await flush()

    expect(input.getAttribute("aria-expanded")).toBe("false")
  })

  function listbox() {
    return document.querySelector('[data-city-autocomplete-target="listbox"]')
  }
})