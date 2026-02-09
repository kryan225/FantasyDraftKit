import BaseModalController from "./base_modal_controller"

/**
 * EditPlayerModalController - Handles the edit player modal
 *
 * Extends BaseModalController to inherit common modal functionality,
 * and adds player editing features.
 *
 * Opens when clicking any player name in the application to allow
 * quick edits to player data (name, positions, projections, etc.)
 *
 * Connects to data-controller="edit-player-modal"
 */
export default class extends BaseModalController {
  static targets = [
    "modal",
    "playerName",
    "playerPositions",
    "playerTeam",
    "playerPrice",
    "playerDraftedPosition",
    "priceField",
    "positionField",
    "googleSearchLink",
    "teamLink",
    "form"
  ]

  connect() {
    super.connect() // Call parent's connect method
    console.log("Edit player modal controller connected")
  }

  /**
   * Open modal with player data
   * Overrides parent's open method to add player-specific setup
   */
  open(event) {
    event.preventDefault()

    const link = event.currentTarget
    const playerId = link.dataset.playerId
    const playerName = link.dataset.playerName
    const playerPositions = link.dataset.playerPositions
    const playerTeamId = link.dataset.playerTeamId
    const playerPrice = link.dataset.playerPrice
    const playerDraftedPosition = link.dataset.playerDraftedPosition

    // Update form action URL to target this specific player
    this.formTarget.action = `/players/${playerId}`

    // Populate form fields with current player data
    this.playerNameTarget.value = playerName || ''
    this.playerPositionsTarget.value = playerPositions || ''
    this.playerTeamTarget.value = playerTeamId || ''

    // Update Google search link with player name
    const searchQuery = encodeURIComponent(playerName || '')
    this.googleSearchLinkTarget.href = `https://www.google.com/search?q=${searchQuery}`

    // Set price field - "N/A" for undrafted, actual price for drafted
    if (playerTeamId && playerPrice) {
      this.playerPriceTarget.value = playerPrice
      this.playerPriceTarget.readOnly = false
      this.playerPriceTarget.type = 'number'
      this.playerPriceTarget.min = '1'
    } else {
      this.playerPriceTarget.value = 'N/A'
      this.playerPriceTarget.readOnly = true
      this.playerPriceTarget.type = 'text'
    }

    this.playerDraftedPositionTarget.value = playerDraftedPosition || ''

    // Show/hide position field based on team selection
    this.onTeamChange()

    // Call parent's open method to show modal
    super.open()
  }

  /**
   * Handle team dropdown change
   * Update price field state, show/hide position field, and update team link based on team selection
   */
  onTeamChange() {
    const teamSelected = this.playerTeamTarget.value !== ''
    const teamId = this.playerTeamTarget.value

    if (teamSelected) {
      // Team selected - make price field editable number input
      this.playerPriceTarget.readOnly = false
      this.playerPriceTarget.type = 'number'
      this.playerPriceTarget.min = '1'
      if (this.playerPriceTarget.value === 'N/A' || !this.playerPriceTarget.value) {
        this.playerPriceTarget.value = '1'
      }
      this.positionFieldTarget.style.display = 'block'

      // Show team link and update href
      this.teamLinkTarget.style.display = 'inline'
      this.teamLinkTarget.href = `/teams/${teamId}`
    } else {
      // No team selected - set price to N/A and make readonly
      this.playerPriceTarget.type = 'text'
      this.playerPriceTarget.readOnly = true
      this.playerPriceTarget.value = 'N/A'
      this.positionFieldTarget.style.display = 'none'

      // Hide team link
      this.teamLinkTarget.style.display = 'none'
    }
  }

  /**
   * Handle form submission
   * Validates inputs before allowing Turbo to submit
   */
  async submit(event) {
    const playerName = this.playerNameTarget.value.trim()
    const positions = this.playerPositionsTarget.value.trim()
    const teamSelected = this.playerTeamTarget.value !== ''
    const price = this.playerPriceTarget.value
    const draftedPosition = this.playerDraftedPositionTarget.value

    // Client-side validation with confirmation modal
    if (!playerName) {
      event.preventDefault()
      await this.showValidationError("Player name is required")
      return
    }

    if (!positions) {
      event.preventDefault()
      await this.showValidationError("At least one position is required")
      return
    }

    // Validate draft-specific fields when assigning to a team
    if (teamSelected) {
      // Skip price validation if value is "N/A" (shouldn't happen, but defensive)
      if (price !== 'N/A' && (!price || parseInt(price) < 1)) {
        event.preventDefault()
        await this.showValidationError("Draft price must be at least $1")
        return
      }

      if (!draftedPosition) {
        event.preventDefault()
        await this.showValidationError("Please select a roster position")
        return
      }
    }

    // Set loading state on submit button
    const submitButton = event.target.querySelector('button[type="submit"]')
    this.setSubmitLoading(submitButton, "Saving...")

    // Form will submit via Turbo, parent class will handle auto-close on success
  }

  /**
   * Show validation error using confirmation modal
   * @param {string} message - Error message to display
   */
  async showValidationError(message) {
    const confirmationModal = this.application.getControllerForElementAndIdentifier(
      document.querySelector("[data-controller='confirmation-modal']"),
      "confirmation-modal"
    )

    await confirmationModal.confirm("Validation Error", message, {
      showCancel: false,
      confirmText: "OK"
    })
  }
}
