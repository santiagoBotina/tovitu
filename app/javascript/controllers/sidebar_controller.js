import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["sidebar", "overlay", "mainWrapper", "brandLink", "collapseButton", "collapseIcon", "expandIcon"]

  connect() {
    this._lastMobile = this.isMobile()
    this.restoreState()
    this.closeOnNavigate()
    this._resizeHandler = () => this.onResize()
    window.addEventListener("resize", this._resizeHandler)
  }

  disconnect() {
    window.removeEventListener("resize", this._resizeHandler)
    this._cleanupNavigation?.()
  }

  toggle() {
    if (this.isMobile()) {
      this.toggleMobile()
    } else {
      this.toggleDesktop()
    }
  }

  toggleDesktop() {
    if (this.isExpanded()) {
      this.collapse()
    } else {
      this.expand()
    }
  }

  expand() {
    this.sidebarTarget.classList.remove("md:w-16")
    this.sidebarTarget.classList.add("md:w-64")

    if (this.hasMainWrapperTarget) {
      this.mainWrapperTarget.classList.remove("md:ml-16")
      this.mainWrapperTarget.classList.add("md:ml-64")
    }

    this.sidebarTarget.querySelectorAll("[data-sidebar-label]").forEach(
      el => el.classList.remove("md:hidden")
    )

    this.updateCollapseState(true)
    localStorage.setItem("tovitu:sidebar", "expanded")
  }

  collapse() {
    this.sidebarTarget.classList.remove("md:w-64")
    this.sidebarTarget.classList.add("md:w-16")

    if (this.hasMainWrapperTarget) {
      this.mainWrapperTarget.classList.remove("md:ml-64")
      this.mainWrapperTarget.classList.add("md:ml-16")
    }

    this.sidebarTarget.querySelectorAll("[data-sidebar-label]").forEach(
      el => el.classList.add("md:hidden")
    )

    this.updateCollapseState(false)
    localStorage.setItem("tovitu:sidebar", "collapsed")
  }

  updateCollapseState(expanded) {
    if (this.hasBrandLinkTarget) {
      this.brandLinkTarget.classList.toggle("md:hidden", !expanded)
    }

    if (this.hasCollapseButtonTarget) {
      const button = this.collapseButtonTarget
      button.setAttribute("aria-expanded", String(expanded))
      button.setAttribute("aria-label", expanded ? button.dataset.collapseLabel : button.dataset.expandLabel)

      // Right-aligned when expanded, centered when collapsed
      button.classList.toggle("md:ml-auto", expanded)
      button.classList.toggle("md:mx-auto", !expanded)
    }

    if (this.hasCollapseIconTarget) {
      this.collapseIconTarget.classList.toggle("hidden", !expanded)
    }

    if (this.hasExpandIconTarget) {
      this.expandIconTarget.classList.toggle("hidden", expanded)
    }
  }

  toggleMobile() {
    if (this.sidebarTarget.classList.contains("-translate-x-full")) {
      this.openMobile()
    } else {
      this.closeMobile()
    }
  }

  openMobile() {
    this.sidebarTarget.classList.remove("-translate-x-full")
    this.overlayTarget.classList.remove("hidden")
    document.body.classList.add("overflow-hidden")
  }

  closeMobile() {
    this.sidebarTarget.classList.add("-translate-x-full")
    this.overlayTarget.classList.add("hidden")
    document.body.classList.remove("overflow-hidden")
  }

  isExpanded() {
    return this.sidebarTarget.classList.contains("md:w-64")
  }

  isMobile() {
    return window.innerWidth < 768
  }

  restoreState() {
    if (this.isMobile()) {
      this.sidebarTarget.classList.add("-translate-x-full")
      return
    }

    const saved = localStorage.getItem("tovitu:sidebar")

    if (saved === "expanded") {
      this.expand()
    } else {
      this.collapse()
    }
  }

  onResize() {
    const nowMobile = this.isMobile()
    if (nowMobile === this._lastMobile) return
    this._lastMobile = nowMobile

    if (nowMobile) {
      this.closeMobile()
    } else {
      const saved = localStorage.getItem("tovitu:sidebar")
      if (saved === "expanded") this.expand()
      else this.collapse()
    }
  }

  closeOnNavigate() {
    const handler = () => {
      if (this.isMobile()) this.closeMobile()
    }
    document.addEventListener("turbo:before-render", handler)
    this._cleanupNavigation = () =>
      document.removeEventListener("turbo:before-render", handler)
  }
}
