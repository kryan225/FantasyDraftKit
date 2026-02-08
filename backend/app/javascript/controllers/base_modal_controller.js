import { Controller } from "@hotwired/stimulus"

/**
 * BaseModalController - Reusable base class for modal dialogs
 *
 * This controller provides common modal functionality that can be inherited
 * by specific modal implementations. It follows the DRY principle and provides
 * tested, reliable modal behavior.
 *
 * Features:
 * - Open/close modal with proper state management
 * - Close on outside click
 * - Close on Escape key
 * - Prevent body scrolling when modal is open
 * - Auto-close on form submission success (via Turbo Stream)
 * - Reset form on close
 *
 * Usage:
 *   import BaseModalController from "./base_modal_controller"
 *
 *   export default class extends BaseModalController {
 *     // Add custom behavior here
 *   }
 */
export default class extends Controller {
  static targets = ["modal"]

  connect() {
    // Bind escape key handler
    this.handleEscape = this.handleEscape.bind(this)

    // Set up turbo:submit-end listener to handle successful submissions
    this.element.addEventListener('turbo:submit-end', this.handleSubmitEnd.bind(this))
  }

  disconnect() {
    // Clean up event listeners
    document.removeEventListener('keydown', this.handleEscape)
  }

  /**
   * Open the modal
   * Called via data-action="click->modal#open" or programmatically
   */
  open(event) {
    if (event) {
      event.preventDefault()
    }

    this.modalTarget.classList.remove("hidden")
    document.body.style.overflow = "hidden"

    // Add escape key listener when modal opens
    document.addEventListener('keydown', this.handleEscape)

    // Dispatch custom event for any listeners
    this.dispatch('opened', { detail: { modal: this.element } })
  }

  /**
   * Close the modal
   * Called via data-action="click->modal#close" or programmatically
   */
  close(event) {
    if (event) {
      event.preventDefault()
    }

    this.modalTarget.classList.add("hidden")
    document.body.style.overflow = ""

    // Remove escape key listener when modal closes
    document.removeEventListener('keydown', this.handleEscape)

    // Reset form if present
    const form = this.element.querySelector('form')
    if (form) {
      form.reset()
    }

    // Dispatch custom event for any listeners
    this.dispatch('closed', { detail: { modal: this.element } })
  }

  /**
   * Close modal when clicking outside the modal content
   */
  closeOnOutsideClick(event) {
    // Check if click is directly on the modal overlay (not on modal content)
    if (event.target === this.modalTarget) {
      this.close(event)
    }
  }

  /**
   * Close modal on Escape key
   */
  handleEscape(event) {
    if (event.key === 'Escape' && !this.modalTarget.classList.contains('hidden')) {
      this.close()
    }
  }

  /**
   * Handle Turbo form submission completion
   * Auto-close modal on successful submission (2xx response)
   */
  handleSubmitEnd(event) {
    const { success, fetchResponse } = event.detail

    // Close modal on successful submission
    if (success && fetchResponse && fetchResponse.succeeded) {
      this.close()
    }

    // Re-enable submit button on error
    if (!success) {
      const submitButton = this.element.querySelector('button[type="submit"]')
      if (submitButton) {
        submitButton.disabled = false
        // Restore original text if it was changed
        if (submitButton.dataset.originalText) {
          submitButton.textContent = submitButton.dataset.originalText
        }
      }
    }
  }

  /**
   * Helper method to disable submit button and show loading state
   * Call this from child classes in their submit handlers
   */
  setSubmitLoading(submitButton, loadingText = "Submitting...") {
    if (submitButton) {
      submitButton.dataset.originalText = submitButton.textContent
      submitButton.disabled = true
      submitButton.textContent = loadingText
    }
  }

  /**
   * Stimulus custom events helper
   * This allows child controllers to listen for modal events:
   *   element.addEventListener('modal:opened', (e) => { ... })
   */
  dispatch(name, detail = {}) {
    const event = new CustomEvent(`${this.identifier}:${name}`, {
      detail,
      bubbles: true,
      cancelable: true
    })
    this.element.dispatchEvent(event)
  }
}
