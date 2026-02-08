import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="collapsible"
export default class extends Controller {
  static targets = ["content", "icon"]

  connect() {
    // Check localStorage for saved state
    const storageKey = this.element.dataset.collapsibleKey
    if (storageKey) {
      const isCollapsed = localStorage.getItem(storageKey) === "true"
      if (isCollapsed) {
        this.collapse(false) // false = no animation on initial load
      }
    }
  }

  toggle() {
    if (this.contentTarget.classList.contains("collapsed")) {
      this.expand()
    } else {
      this.collapse(true)
    }
  }

  collapse(animate = true) {
    if (!animate) {
      this.contentTarget.style.transition = "none"
    }

    this.contentTarget.classList.add("collapsed")
    this.iconTarget.textContent = "▶"

    if (!animate) {
      // Force reflow to re-enable transitions
      this.contentTarget.offsetHeight
      this.contentTarget.style.transition = ""
    }

    // Save state
    const storageKey = this.element.dataset.collapsibleKey
    if (storageKey) {
      localStorage.setItem(storageKey, "true")
    }
  }

  expand() {
    this.contentTarget.classList.remove("collapsed")
    this.iconTarget.textContent = "▼"

    // Save state
    const storageKey = this.element.dataset.collapsibleKey
    if (storageKey) {
      localStorage.setItem(storageKey, "false")
    }
  }
}
