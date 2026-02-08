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
    "playerMlbTeam",
    "playerValue",
    "playerIsDrafted",
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
    const playerMlbTeam = link.dataset.playerMlbTeam
    const playerValue = link.dataset.playerValue
    const playerIsDrafted = link.dataset.playerIsDrafted === 'true'

    // Update form action URL to target this specific player
    this.formTarget.action = `/players/${playerId}`

    // Populate form fields with current player data
    this.playerNameTarget.value = playerName || ''
    this.playerPositionsTarget.value = playerPositions || ''
    this.playerMlbTeamTarget.value = playerMlbTeam || ''
    this.playerValueTarget.value = playerValue || ''
    this.playerIsDraftedTarget.checked = playerIsDrafted

    // Call parent's open method to show modal
    super.open()
  }

  /**
   * Handle form submission
   * Validates inputs before allowing Turbo to submit
   */
  submit(event) {
    const playerName = this.playerNameTarget.value.trim()
    const positions = this.playerPositionsTarget.value.trim()

    // Client-side validation
    if (!playerName) {
      alert("Player name is required")
      event.preventDefault()
      return
    }

    if (!positions) {
      alert("At least one position is required")
      event.preventDefault()
      return
    }

    // Set loading state on submit button
    const submitButton = event.target.querySelector('button[type="submit"]')
    this.setSubmitLoading(submitButton, "Saving...")

    // Form will submit via Turbo, parent class will handle auto-close on success
  }
}
