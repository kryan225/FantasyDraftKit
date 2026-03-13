import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["toggle"]

  connect() {
    const saved = localStorage.getItem("darkMode")
    if (saved === "true") {
      document.documentElement.classList.add("dark")
    }
    this.updateToggleLabel()
  }

  toggle() {
    document.documentElement.classList.toggle("dark")
    const isDark = document.documentElement.classList.contains("dark")
    localStorage.setItem("darkMode", isDark)
    this.updateToggleLabel()
  }

  updateToggleLabel() {
    if (!this.hasToggleTarget) return
    const isDark = document.documentElement.classList.contains("dark")
    this.toggleTarget.textContent = isDark ? "Switch to Light Mode" : "Switch to Dark Mode"
  }
}
