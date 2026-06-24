import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["sidebar", "overlay", "mainWrapper"]

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

    localStorage.setItem("tovitu:sidebar", "collapsed")
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
