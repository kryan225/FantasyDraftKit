import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="draft-modal"
export default class extends Controller {
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
    console.log("Draft modal controller connected")

    // Listen for draft success event to close modal
    document.addEventListener('draft-success', () => {
      this.close()
    })
  }

  // Open modal with player data
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

    // Show modal
    this.modalTarget.classList.remove("hidden")
    document.body.style.overflow = "hidden" // Prevent background scrolling
  }

  // Close modal
  close(event) {
    if (event) {
      event.preventDefault()
    }
    this.modalTarget.classList.add("hidden")
    document.body.style.overflow = "" // Restore scrolling
  }

  // Close modal when clicking outside
  closeOnOutsideClick(event) {
    if (event.target === this.modalTarget) {
      this.close(event)
    }
  }

  // Populate position select dropdown based on player's positions
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

  // Calculate eligible positions based on roster rules
  // - All players can play UTIL
  // - 1B and 3B can play CI (Corner Infield)
  // - 2B and SS can play MI (Middle Infield)
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

  // Handle form submission - now uses Turbo Streams
  submit(event) {
    // Let the form submit naturally - Turbo will handle it
    // Just do client-side validation first

    const price = parseInt(this.priceInputTarget.value)
    const teamId = this.teamSelectTarget.value

    // Validation
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

    // Disable submit button to prevent double submission
    const submitButton = event.target.querySelector('button[type="submit"]')
    if (submitButton) {
      submitButton.disabled = true
      submitButton.textContent = "Drafting..."
    }

    // Form will submit via Turbo, no need to prevent default
  }
}
