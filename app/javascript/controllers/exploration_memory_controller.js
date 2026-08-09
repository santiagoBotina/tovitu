import { Controller } from "@hotwired/stimulus"

// Persists filter/search state locally and restores it on the homepage.
//
//  save mode (pets index): writes tovitu:exploration on connect (from the
//    current URL params) and debounced while the filter form changes, plus
//    on submit.
//  resume mode (landing): reveals the "Pick up where you left off" panel
//    when a recent exploration entry exists, fills filter chips, points the
//    resume link at /pets with those params, and exposes a clear affordance.
//
// Everything is client-side and PII-free. Respects localStorage availability.
const EXPLORATION_KEY = "tovitu:exploration"
const INTERESTS_KEY = "tovitu:interests"
const FILTER_PARAMS = [
  "query", "species", "breed", "age_category", "size", "sex",
  "city", "state", "good_with_children", "good_with_dogs", "good_with_cats",
]

export default class extends Controller {
  static targets = ["panel", "chips", "resumeLink", "interestCount", "interestText"]
  static values = {
    mode: String,
    baseUrl: String,
    labels: Object,
    one: String,
    other: String,
    more: String,
    maxAgeDays: { type: Number, default: 14 },
    signedIn: Boolean,
  }

  connect() {
    if (this.modeValue === "save") {
      this.setupSave()
    } else if (this.modeValue === "resume") {
      this.setupResume()
    }
  }

  // ───────────────────────── Save mode ─────────────────────────

  setupSave() {
    // Exploration memory targets returning visitors who haven't signed up.
    // Signed-in users are redirected away from the landing page, so their
    // session already lives server-side — skip storing client-side state.
    if (this.signedInValue) return
    this.saveFromParams(new URLSearchParams(window.location.search))
    const form = this.element.querySelector("form[method='get']")
    if (!form) return
    const debounced = this.debounce(() => this.saveFromForm(form), 500)
    form.addEventListener("submit", () => this.saveFromForm(form))
    form.addEventListener("change", debounced)
    form.addEventListener("input", debounced)
  }

  saveFromParams(searchParams) {
    const params = {}
    for (const key of FILTER_PARAMS) {
      const value = searchParams.get(key)
      if (value) params[key] = value
    }
    if (Object.keys(params).length > 0) this.writeExploration(params)
  }

  saveFromForm(form) {
    const params = {}
    for (const key of FILTER_PARAMS) {
      const field = form.elements[key]
      if (field && field.value && field.value !== "") params[key] = field.value
    }
    this.writeExploration(params)
  }

  writeExploration(params) {
    try {
      localStorage.setItem(EXPLORATION_KEY, JSON.stringify({
        saved_at: new Date().toISOString(),
        params,
      }))
    } catch {
      // Storage unavailable — skip persisting.
    }
  }

  // ─────────────────────── Resume mode ─────────────────────────

  setupResume() {
    const data = this.readExploration()
    if (!data || this.isStale(data)) return
    this.renderChips(data.params)
    this.renderInterests()
    if (this.hasResumeLinkTarget) {
      this.resumeLinkTarget.href = this.buildResumeUrl(data.params)
    }
    if (this.hasPanelTarget) this.panelTarget.classList.remove("hidden")
    this.element.classList.remove("hidden")
  }

  readExploration() {
    try {
      const raw = JSON.parse(localStorage.getItem(EXPLORATION_KEY) || "null")
      if (!raw || !raw.params || typeof raw.params !== "object") return null
      return raw
    } catch {
      return null
    }
  }

  isStale(data) {
    const savedAt = new Date(data.saved_at)
    if (Number.isNaN(savedAt.getTime())) return true
    const maxAgeMs = this.maxAgeDaysValue * 24 * 60 * 60 * 1000
    return Date.now() - savedAt.getTime() > maxAgeMs
  }

  buildResumeUrl(params) {
    const search = new URLSearchParams()
    for (const key of FILTER_PARAMS) {
      if (params[key]) search.set(key, params[key])
    }
    const base = this.baseUrlValue || "/pets"
    const qs = search.toString()
    return qs ? `${base}?${qs}` : base
  }

  renderChips(params) {
    if (!this.hasChipsTarget) return
    this.chipsTarget.innerHTML = ""
    const chips = []
    for (const key of FILTER_PARAMS) {
      const value = params[key]
      if (!value) continue
      const label = this.labelFor(key, value)
      if (label) chips.push(label)
    }
    const maxChips = 4
    const visible = chips.slice(0, maxChips)
    const more = chips.length - visible.length
    for (const label of visible) {
      this.chipsTarget.appendChild(this.buildChip(label))
    }
    if (more > 0) {
      const label = (this.moreValue || "+%{count}").replace("%{count}", more)
      this.chipsTarget.appendChild(this.buildChip(label, true))
    }
  }

  labelFor(key, value) {
    const map = this.labelsValue?.[key]
    if (typeof map === "string") return map
    if (map && typeof map === "object" && map[value]) return map[value]
    return value
  }

  buildChip(label, muted = false) {
    const span = document.createElement("span")
    span.className = "inline-flex items-center px-3 py-1 rounded-full text-sm font-medium " +
      (muted ? "bg-neutral-100 text-neutral-500" : "bg-secondary-100 text-secondary-800")
    span.textContent = label
    return span
  }

  renderInterests() {
    const count = this.readInterests().length
    if (!this.hasInterestCountTarget || count === 0) return
    const template = count === 1 ? this.oneValue : this.otherValue
    if (this.hasInterestTextTarget) {
      this.interestTextTarget.textContent = (template || "").replace("%{count}", count)
    }
    this.interestCountTarget.classList.remove("hidden")
  }

  readInterests() {
    try {
      const raw = JSON.parse(localStorage.getItem(INTERESTS_KEY) || "[]")
      return Array.isArray(raw) ? raw : []
    } catch {
      return []
    }
  }

  showInterests(event) {
    event.preventDefault()
    document.dispatchEvent(new CustomEvent("tovitu:interest-prompt"))
  }

  clear(event) {
    event.preventDefault()
    try {
      localStorage.removeItem(EXPLORATION_KEY)
    } catch {
      // ignore
    }
    if (this.hasPanelTarget) this.panelTarget.classList.add("hidden")
    this.element.classList.add("hidden")
  }

  // ───────────────────────── helpers ───────────────────────────

  debounce(fn, wait) {
    let timer
    return (...args) => {
      clearTimeout(timer)
      timer = setTimeout(() => fn(...args), wait)
    }
  }
}
