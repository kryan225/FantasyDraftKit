import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="player-interest"
// Toggles player interest by clicking anywhere on the row,
// ignoring clicks on interactive elements (buttons, links, action menus).
export default class extends Controller {
  static targets = ["form"]

  toggle(event) {
    if (event.target.closest("a, button, .row-actions-container")) return
    this.formTarget.requestSubmit()
  }
}
