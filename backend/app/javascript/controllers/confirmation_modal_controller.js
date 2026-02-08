import BaseModalController from "./base_modal_controller"

/**
 * ConfirmationModalController - Reusable confirmation dialog
 * 
 * Extends BaseModalController to provide a standardized confirmation modal
 * that replaces JavaScript alert() calls with a better UX.
 * 
 * Usage:
 *   // From another controller:
 *   const confirmed = await this.application.getControllerForElementAndIdentifier(
 *     document.querySelector("[data-controller='confirmation-modal']"),
 *     "confirmation-modal"
 *   ).confirm("Are you sure?", "This action cannot be undone")
 * 
 *   if (confirmed) {
 *     // User clicked OK
 *   } else {
 *     // User clicked Cancel
 *   }
 */
export default class extends BaseModalController {
  static targets = [
    "modal",
    "title",
    "message",
    "confirmButton",
    "cancelButton"
  ]

  /**
   * Show confirmation modal and return a promise
   * @param {string} title - Modal title (e.g., "Validation Error")
   * @param {string} message - Modal message (e.g., "Player name is required")
   * @param {Object} options - Optional configuration
   * @returns {Promise<boolean>} - Resolves to true if confirmed, false if cancelled
   */
  confirm(title, message, options = {}) {
    return new Promise((resolve) => {
      // Store resolver for button handlers
      this.resolver = resolve

      // Set content
      this.titleTarget.textContent = title
      this.messageTarget.textContent = message

      // Configure buttons
      const confirmText = options.confirmText || "OK"
      const cancelText = options.cancelText || "Cancel"
      const confirmClass = options.danger ? "btn-danger" : "btn-primary"

      this.confirmButtonTarget.textContent = confirmText
      this.confirmButtonTarget.className = `btn ${confirmClass} btn-sm`
      
      // Show/hide cancel button
      if (options.showCancel === false) {
        this.cancelButtonTarget.style.display = "none"
      } else {
        this.cancelButtonTarget.style.display = ""
        this.cancelButtonTarget.textContent = cancelText
      }

      // Open modal
      super.open()
    })
  }

  /**
   * User clicked confirm button
   */
  handleConfirm() {
    this.close()
    if (this.resolver) {
      this.resolver(true)
      this.resolver = null
    }
  }

  /**
   * User clicked cancel button or closed modal
   */
  handleCancel() {
    this.close()
    if (this.resolver) {
      this.resolver(false)
      this.resolver = null
    }
  }

  /**
   * Override close to reject if user escapes or clicks outside
   */
  close() {
    super.close()
    if (this.resolver) {
      this.resolver(false)
      this.resolver = null
    }
  }
}
