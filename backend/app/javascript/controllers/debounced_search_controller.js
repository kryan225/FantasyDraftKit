import { Controller } from "@hotwired/stimulus"

const REFOCUS_KEY = "debounced-search-refocus"

export default class extends Controller {
  static values = { delay: { type: Number, default: 300 } }

  connect() {
    this._timeout = null

    // After Turbo re-renders the page, refocus and place cursor at end
    if (sessionStorage.getItem(REFOCUS_KEY) === "true") {
      sessionStorage.removeItem(REFOCUS_KEY)
      const len = this.element.value.length
      this.element.focus()
      this.element.setSelectionRange(len, len)
    }
  }

  search() {
    clearTimeout(this._timeout)
    this._timeout = setTimeout(() => {
      sessionStorage.setItem(REFOCUS_KEY, "true")
      this.element.closest("form").requestSubmit()
    }, this.delayValue)
  }

  disconnect() {
    clearTimeout(this._timeout)
  }
}
