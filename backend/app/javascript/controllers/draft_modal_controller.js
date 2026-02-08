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

  // Handle form submission
  async submit(event) {
    event.preventDefault()

    const price = parseInt(this.priceInputTarget.value)
    const teamId = this.teamSelectTarget.value
    const playerId = this.playerIdTarget.value
    const position = this.positionSelectTarget.value

    // Validation
    if (!teamId) {
      alert("Please select a team")
      return
    }

    if (!price || price < 1) {
      alert("Please enter a valid price (minimum $1)")
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
        return
      }
    }

    // Get league ID from URL or data attribute
    const leagueId = this.getLeagueId()
    if (!leagueId) {
      alert("Error: Could not determine league ID")
      return
    }

    // Disable submit button to prevent double submission
    const submitButton = event.target.querySelector('button[type="submit"]')
    if (submitButton) {
      submitButton.disabled = true
      submitButton.textContent = "Drafting..."
    }

    try {
      // Submit to API
      const response = await this.submitDraftPick(leagueId, {
        team_id: teamId,
        player_id: playerId,
        price: price,
        is_keeper: false
      })

      if (response.ok) {
        // Success! Reload page to show updated draft board
        window.location.reload()
      } else {
        const data = await response.json()
        const errorMessage = data.errors ? data.errors.join(", ") : "Failed to draft player"
        alert(`Error: ${errorMessage}`)

        // Re-enable submit button
        if (submitButton) {
          submitButton.disabled = false
          submitButton.textContent = "Confirm Draft"
        }
      }
    } catch (error) {
      console.error("Draft submission error:", error)
      alert("An error occurred while drafting the player. Please try again.")

      // Re-enable submit button
      if (submitButton) {
        submitButton.disabled = false
        submitButton.textContent = "Confirm Draft"
      }
    }
  }

  // Submit draft pick to API
  async submitDraftPick(leagueId, draftPickData) {
    const csrfToken = document.querySelector('meta[name="csrf-token"]')?.content

    return fetch(`/api/v1/leagues/${leagueId}/draft_picks`, {
      method: "POST",
      headers: {
        "Content-Type": "application/json",
        "X-CSRF-Token": csrfToken,
        "Accept": "application/json"
      },
      body: JSON.stringify({
        draft_pick: draftPickData
      })
    })
  }

  // Get league ID from current URL or page data
  getLeagueId() {
    // Try to get from URL parameter
    const urlParams = new URLSearchParams(window.location.search)
    if (urlParams.has('league_id')) {
      return urlParams.get('league_id')
    }

    // Try to get from page (e.g., data attribute on body or container)
    const leagueIdElement = document.querySelector('[data-league-id]')
    if (leagueIdElement) {
      return leagueIdElement.dataset.leagueId
    }

    // Fallback: try to extract from breadcrumb or other page elements
    const backLink = document.querySelector('a[href*="/leagues/"]')
    if (backLink) {
      const match = backLink.href.match(/\/leagues\/(\d+)/)
      if (match) {
        return match[1]
      }
    }

    return null
  }
}
