import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="row-actions"
export default class extends Controller {
  static targets = ["menu"]

  toggle(event) {
    event.stopPropagation()

    // Close all other open menus
    document.querySelectorAll('.row-actions-menu.show').forEach(menu => {
      if (menu !== this.menuTarget) {
        menu.classList.remove('show')
      }
    })

    // Toggle this menu
    this.menuTarget.classList.toggle('show')
  }

  close(event) {
    // Don't close if clicking inside the menu
    if (this.element.contains(event.target)) {
      return
    }

    this.menuTarget.classList.remove('show')
  }

  connect() {
    // Close menu when clicking outside
    this.boundClose = this.close.bind(this)
    document.addEventListener('click', this.boundClose)
  }

  disconnect() {
    document.removeEventListener('click', this.boundClose)
  }
}
