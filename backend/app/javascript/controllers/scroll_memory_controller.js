import { Controller } from "@hotwired/stimulus"

/**
 * ScrollMemoryController - Saves and restores scroll position
 *
 * Remembers the element's scroll position across Turbo navigations.
 * Saves on scroll (debounced) and before Turbo visits/renders.
 * Restores synchronously on connect — no requestAnimationFrame needed
 * since Stimulus connects after the element is in the DOM.
 */
export default class extends Controller {
  static values = {
    key: { type: String, default: 'scrollPosition' }
  }

  connect() {
    this.restoreScroll()

    this.boundSaveScroll = this.saveScroll.bind(this)
    this.boundDebouncedSave = this.debounce(this.boundSaveScroll, 100)

    this.element.addEventListener('scroll', this.boundDebouncedSave)
    document.addEventListener('turbo:before-visit', this.boundSaveScroll)
    document.addEventListener('turbo:before-render', this.boundSaveScroll)
  }

  disconnect() {
    this.element.removeEventListener('scroll', this.boundDebouncedSave)
    document.removeEventListener('turbo:before-visit', this.boundSaveScroll)
    document.removeEventListener('turbo:before-render', this.boundSaveScroll)
  }

  saveScroll() {
    sessionStorage.setItem(this.keyValue, JSON.stringify({
      elementX: this.element.scrollLeft,
      elementY: this.element.scrollTop
    }))
  }

  restoreScroll() {
    const saved = sessionStorage.getItem(this.keyValue)
    if (!saved) return

    try {
      const { elementX, elementY } = JSON.parse(saved)
      this.element.scrollLeft = elementX
      this.element.scrollTop = elementY
    } catch (e) {
      console.error('Failed to restore scroll position:', e)
    }
  }

  debounce(func, wait) {
    let timeout
    return function (...args) {
      clearTimeout(timeout)
      timeout = setTimeout(() => func(...args), wait)
    }
  }
}
