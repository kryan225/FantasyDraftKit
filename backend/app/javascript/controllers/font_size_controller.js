import { Controller } from "@hotwired/stimulus"

const MIN_SIZE = 75
const MAX_SIZE = 150
const STEP = 5
const DEFAULT_SIZE = 100

export default class extends Controller {
  static targets = ["display"]

  connect() {
    const saved = localStorage.getItem("globalFontSize")
    this.size = saved ? parseInt(saved, 10) : DEFAULT_SIZE
    this.apply()
  }

  increase() {
    if (this.size < MAX_SIZE) {
      this.size += STEP
      this.save()
    }
  }

  decrease() {
    if (this.size > MIN_SIZE) {
      this.size -= STEP
      this.save()
    }
  }

  reset() {
    this.size = DEFAULT_SIZE
    this.save()
  }

  save() {
    localStorage.setItem("globalFontSize", this.size)
    this.apply()
  }

  apply() {
    document.documentElement.style.fontSize = `${this.size}%`
    if (this.hasDisplayTarget) {
      this.displayTarget.textContent = `${this.size}%`
    }
  }
}
