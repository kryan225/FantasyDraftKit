import BaseModalController from "./base_modal_controller"

/**
 * DraftModalController - Handles the player draft modal
 *
 * Extends BaseModalController to inherit common modal functionality,
 * and adds draft-specific features like position eligibility calculation.
 *
 * Connects to data-controller="draft-modal"
 */
export default class extends BaseModalController {
  static targets = [
    "modal",
    "playerName",
    "playerPosition",
    "playerTeam",
    "playerValue",
    "priceInput",
    "teamSelect",
    "positionSelect",
    "playerId"
  ]

  connect() {
    super.connect() // Call parent's connect method
    console.log("Draft modal controller connected")
  }

  /**
   * Open modal with player data
   * Overrides parent's open method to add player-specific setup
   */
  open(event) {
    event.preventDefault()

    const button = event.currentTarget
    const playerId = button.dataset.playerId
    const playerName = button.dataset.playerName
    const playerPositions = button.dataset.playerPositions
    const playerMlbTeam = button.dataset.playerMlbTeam
    const playerValue = button.dataset.playerValue

    // Populate modal with player data
    this.playerNameTarget.textContent = playerName
    this.playerPositionTarget.textContent = playerPositions
    this.playerTeamTarget.textContent = playerMlbTeam
    this.playerValueTarget.textContent = `$${playerValue}`
    this.playerIdTarget.value = playerId

    // Pre-fill price with calculated value
    if (playerValue && playerValue !== "?") {
      this.priceInputTarget.value = Math.round(parseFloat(playerValue))
    } else {
      this.priceInputTarget.value = 1
    }

    // Populate position options based on player's positions
    this.populatePositionOptions(playerPositions)

    // Call parent's open method to show modal
    super.open()
  }

  /**
   * Populate position select dropdown based on player's positions
   * Implements fantasy baseball position eligibility rules
   */
  populatePositionOptions(positions) {
    const positionArray = positions.split('/').map(p => p.trim())
    const eligiblePositions = this.calculateEligiblePositions(positionArray)

    // Clear existing options
    this.positionSelectTarget.innerHTML = ""

    // Add eligible positions
    eligiblePositions.forEach((pos, index) => {
      const option = document.createElement("option")
      option.value = pos
      option.textContent = pos
      if (index === 0) {
        option.selected = true // Select first position by default
      }
      this.positionSelectTarget.appendChild(option)
    })
  }

  /**
   * Calculate eligible positions based on roster rules
   * - All players can play UTIL
   * - 1B and 3B can play CI (Corner Infield)
   * - 2B and SS can play MI (Middle Infield)
   *
   * @param {Array<string>} positions - Player's actual positions
   * @return {Array<string>} - All eligible positions in logical order
   */
  calculateEligiblePositions(positions) {
    const eligible = new Set()

    // Add actual positions
    positions.forEach(pos => {
      eligible.add(pos)
    })

    // Add position-specific eligibility
    if (positions.includes('1B') || positions.includes('3B')) {
      eligible.add('CI') // Corner Infield
    }

    if (positions.includes('2B') || positions.includes('SS')) {
      eligible.add('MI') // Middle Infield
    }

    // All players can play utility
    eligible.add('UTIL')

    // Convert to sorted array (actual positions first, then special positions)
    const specialPositions = ['CI', 'MI', 'UTIL']
    const actualPositions = Array.from(eligible).filter(p => !specialPositions.includes(p))
    const addedSpecialPositions = Array.from(eligible).filter(p => specialPositions.includes(p))

    return [...actualPositions, ...addedSpecialPositions]
  }

  /**
   * Handle form submission
   * Validates inputs before allowing Turbo to submit
   */
  submit(event) {
    const price = parseInt(this.priceInputTarget.value)
    const teamId = this.teamSelectTarget.value

    // Client-side validation
    if (!teamId) {
      alert("Please select a team")
      event.preventDefault()
      return
    }

    if (!price || price < 1) {
      alert("Please enter a valid price (minimum $1)")
      event.preventDefault()
      return
    }

    // Budget validation - check selected team's budget
    const selectedTeamOption = this.teamSelectTarget.options[this.teamSelectTarget.selectedIndex]
    const teamText = selectedTeamOption.text
    const budgetMatch = teamText.match(/\$(\d+) remaining/)
    if (budgetMatch) {
      const remainingBudget = parseInt(budgetMatch[1])
      if (price > remainingBudget) {
        alert(`Price $${price} exceeds team's remaining budget of $${remainingBudget}`)
        event.preventDefault()
        return
      }
    }

    // Set loading state on submit button
    const submitButton = event.target.querySelector('button[type="submit"]')
    this.setSubmitLoading(submitButton, "Drafting...")

    // Form will submit via Turbo, parent class will handle auto-close on success
  }
}
