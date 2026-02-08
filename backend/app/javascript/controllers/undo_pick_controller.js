import { Controller } from "@hotwired/stimulus"

/**
 * UndoPickController - Handles undo confirmation for draft picks
 * 
 * Shows a styled confirmation modal before undoing a draft pick.
 * Replaces the browser's native confirm dialog with ConfirmationModal.
 */
export default class extends Controller {
  static values = {
    pickId: String,
    price: String,
    teamName: String
  }

  /**
   * Handle undo button click
   * Shows confirmation modal before submitting delete request
   */
  async undo(event) {
    event.preventDefault()
    
    const form = event.target.closest('form')
    
    // Get confirmation modal
    const confirmationModal = this.application.getControllerForElementAndIdentifier(
      document.querySelector("[data-controller='confirmation-modal']"),
      "confirmation-modal"
    )

    // Show confirmation dialog
    const confirmed = await confirmationModal.confirm(
      "Undo Draft Pick?",
      `Are you sure you want to undo this pick? This will refund $${this.priceValue} to ${this.teamNameValue}.`,
      {
        danger: true,
        confirmText: "Undo Pick",
        cancelText: "Keep Pick"
      }
    )

    // If confirmed, submit the form
    if (confirmed) {
      form.requestSubmit()
    }
  }
}
