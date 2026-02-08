import { Controller } from "@hotwired/stimulus"

/**
 * ScrollMemoryController - Saves and restores scroll position
 * 
 * Remembers scroll position before page navigation and restores it after.
 * Useful for maintaining scroll position when sorting tables.
 */
export default class extends Controller {
  static values = {
    key: { type: String, default: 'scrollPosition' }
  }

  connect() {
    // Restore scroll position on page load
    this.restoreScroll()

    // Bind event handlers
    this.boundSaveScroll = this.saveScroll.bind(this)
    this.boundThrottledSave = this.throttle(this.boundSaveScroll, 100)

    // Save scroll position as user scrolls
    this.element.addEventListener('scroll', this.boundThrottledSave)
    window.addEventListener('scroll', this.boundThrottledSave)

    // Save scroll position before navigating away
    document.addEventListener('turbo:before-visit', this.boundSaveScroll)
    document.addEventListener('turbo:before-render', this.boundSaveScroll)
  }

  disconnect() {
    this.element.removeEventListener('scroll', this.boundThrottledSave)
    window.removeEventListener('scroll', this.boundThrottledSave)
    document.removeEventListener('turbo:before-visit', this.boundSaveScroll)
    document.removeEventListener('turbo:before-render', this.boundSaveScroll)
  }

  saveScroll() {
    const scrollData = {
      x: window.scrollX,
      y: window.scrollY,
      elementX: this.element.scrollLeft,
      elementY: this.element.scrollTop
    }

    sessionStorage.setItem(this.keyValue, JSON.stringify(scrollData))
  }

  // Throttle function to limit how often we save scroll position
  throttle(func, wait) {
    let timeout
    return function executedFunction(...args) {
      const later = () => {
        clearTimeout(timeout)
        func(...args)
      }
      clearTimeout(timeout)
      timeout = setTimeout(later, wait)
    }
  }

  restoreScroll() {
    const savedData = sessionStorage.getItem(this.keyValue)
    
    if (savedData) {
      try {
        const scrollData = JSON.parse(savedData)
        
        // Restore after a short delay to ensure content is rendered
        requestAnimationFrame(() => {
          // Restore window scroll
          window.scrollTo(scrollData.x, scrollData.y)
          
          // Restore element scroll
          this.element.scrollLeft = scrollData.elementX
          this.element.scrollTop = scrollData.elementY
        })
      } catch (e) {
        console.error('Failed to restore scroll position:', e)
      }
    }
  }
}
