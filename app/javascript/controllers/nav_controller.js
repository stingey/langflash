import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["menu", "toggle"]

  connect() {
    this.close()
    this.handleResize = this.handleResize.bind(this)
    window.addEventListener("resize", this.handleResize)
  }

  disconnect() {
    window.removeEventListener("resize", this.handleResize)
  }

  toggle() {
    if (this.menuTarget.classList.contains("is-open")) {
      this.close()
    } else {
      this.open()
    }
  }

  open() {
    this.menuTarget.classList.add("is-open")
    if (this.hasToggleTarget) {
      this.toggleTarget.setAttribute("aria-expanded", "true")
      this.toggleTarget.setAttribute("aria-label", "Close menu")
    }
  }

  close() {
    this.menuTarget.classList.remove("is-open")
    if (this.hasToggleTarget) {
      this.toggleTarget.setAttribute("aria-expanded", "false")
      this.toggleTarget.setAttribute("aria-label", "Open menu")
    }
  }

  handleResize() {
    if (window.innerWidth > 760) {
      this.close()
    }
  }
}
