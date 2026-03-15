import BaseModalController from "./base_modal_controller"
import { PositionEligibility } from "../utils/position_eligibility"

/**
 * WorksheetDraftModalController - Opens a player-search draft modal from the auction worksheet
 *
 * Clicking an empty roster cell on the worksheet opens this modal, pre-scoped to
 * the team and position of the clicked cell. Users search for eligible available
 * players, select one, enter a price, and submit the draft pick.
 *
 * On success, the worksheet is refreshed via Turbo.visit.
 */
export default class extends BaseModalController {
  static targets = [
    "modal",
    "modalTitle",
    "selectedPlayerName",
    "searchInput",
    "searchResults",
    "playerIdInput",
    "teamIdInput",
    "leagueIdInput",
    "positionSelect",
    "priceInput",
    "toppedCheckbox"
  ]

  static values = {
    activePositions: Array
  }

  connect() {
    super.connect()
    this._searchTimeout = null
    this._selectedPlayer = null
    this._lastResults = []
    this._currentPosition = null
  }

  open(event) {
    const cell = event.currentTarget
    this._currentPosition = cell.dataset.position
    const teamId = cell.dataset.teamId
    const teamName = cell.dataset.teamName
    const leagueId = cell.dataset.leagueId

    // Set hidden form fields
    this.teamIdInputTarget.value = teamId
    this.leagueIdInputTarget.value = leagueId

    // Update modal title
    this.modalTitleTarget.textContent = `Draft ${this._currentPosition} — ${teamName}`

    // Reset UI state
    this._selectedPlayer = null
    this._lastResults = []
    this.playerIdInputTarget.value = ""
    this.searchInputTarget.value = ""
    this.searchResultsTarget.innerHTML = ""
    this.selectedPlayerNameTarget.textContent = "\u00A0"
    this.selectedPlayerNameTarget.classList.add("worksheet-selected-player--empty")
    this.priceInputTarget.value = 1
    this.toppedCheckboxTarget.checked = false

    // Populate position select, defaulting to the clicked slot
    this.populatePositionSelect(this._currentPosition)

    super.open()

    setTimeout(() => {
      this.searchInputTarget.focus()
      this.performSearch()
    }, 50)
  }

  search() {
    clearTimeout(this._searchTimeout)
    this._searchTimeout = setTimeout(() => this.performSearch(), 250)
  }

  async performSearch() {
    const params = new URLSearchParams({ drafted: "false", min_value: "0" })
    if (this._currentPosition) params.set("position", this._currentPosition)
    const q = this.searchInputTarget.value.trim()
    if (q) params.set("search", q)

    try {
      const response = await fetch(`/players/search?${params}`, {
        headers: { Accept: "application/json" }
      })
      const players = await response.json()
      this._lastResults = players
      this.renderResults(players)
    } catch (e) {
      console.error("Player search failed", e)
    }
  }

  renderResults(players) {
    this.searchResultsTarget.innerHTML = ""

    if (players.length === 0) {
      this.searchResultsTarget.innerHTML =
        '<div style="color: var(--text-secondary); padding: 0.5rem 0.75rem; font-size: 0.9em;">No players found</div>'
      return
    }

    players.forEach(player => {
      const row = document.createElement("div")
      row.className = "player-search-result"
      if (this._selectedPlayer?.id === player.id) row.classList.add("selected")

      const val = player.value != null ? `$${player.value}` : "—"
      const adp = player.adp != null ? player.adp : "—"

      row.innerHTML = `
        <span class="psr-name">${player.name}</span>
        <span class="psr-pos">${player.positions || ""}</span>
        <span class="psr-value">${val}</span>
        <span class="psr-adp">ADP: ${adp}</span>
      `
      row.addEventListener("click", () => this.selectPlayer(player))
      this.searchResultsTarget.appendChild(row)
    })
  }

  selectPlayer(player) {
    this._selectedPlayer = player
    this.playerIdInputTarget.value = player.id

    // Show player name + positions in chip below search
    this.selectedPlayerNameTarget.textContent = `${player.name}  ·  ${player.positions || ""}`
    this.selectedPlayerNameTarget.classList.remove("worksheet-selected-player--empty")

    // Update position select to show eligible positions for this player
    this.updatePositionSelect(player.positions)

    // Pre-fill price with rounded value
    if (player.value && player.value > 0) {
      this.priceInputTarget.value = Math.round(player.value)
    } else {
      this.priceInputTarget.value = 1
    }

    // Re-render results list to highlight selected row
    this.renderResults(this._lastResults)

    this.priceInputTarget.focus()
  }

  /**
   * Populate position select with all active league positions, defaulting to the clicked slot.
   */
  populatePositionSelect(defaultPosition) {
    const active = this.hasActivePositionsValue ? this.activePositionsValue : []
    this.positionSelectTarget.innerHTML = ""
    active.forEach(pos => {
      const option = document.createElement("option")
      option.value = pos
      option.textContent = pos
      option.selected = pos === defaultPosition
      this.positionSelectTarget.appendChild(option)
    })
  }

  /**
   * After a player is selected, filter position select to only show positions that player
   * is eligible for, keeping the clicked slot as the default if eligible.
   */
  updatePositionSelect(playerPositions) {
    if (!playerPositions) return

    const posArray = playerPositions.split(/[,\/]/).map(p => p.trim())
    const eligible = PositionEligibility.getEligiblePositions(posArray)
    const active = this.hasActivePositionsValue ? this.activePositionsValue : []
    const filtered = active.length > 0 ? eligible.filter(p => active.includes(p)) : eligible

    // Sort: natural positions first, then flex (CI, MI, UTIL)
    const flex = ["CI", "MI", "UTIL"]
    const sorted = [
      ...filtered.filter(p => !flex.includes(p)),
      ...filtered.filter(p => flex.includes(p))
    ]

    this.positionSelectTarget.innerHTML = ""
    sorted.forEach(pos => {
      const option = document.createElement("option")
      option.value = pos
      option.textContent = pos
      option.selected = pos === this._currentPosition
      this.positionSelectTarget.appendChild(option)
    })

    // If the clicked position isn't eligible for this player, default to the first option
    if (!sorted.includes(this._currentPosition) && sorted.length > 0) {
      this.positionSelectTarget.value = sorted[0]
    }
  }

  async submit(event) {
    if (!this._selectedPlayer) {
      event.preventDefault()
      await this.showValidationError("Please select a player first")
      return
    }

    const price = parseInt(this.priceInputTarget.value)
    if (!price || price < 1) {
      event.preventDefault()
      await this.showValidationError("Please enter a valid price (minimum $1)")
      return
    }

    const submitButton = event.target.querySelector('button[type="submit"]')
    this.setSubmitLoading(submitButton, "Drafting...")
  }

  /**
   * Reload the worksheet after a successful draft so the new pick is reflected.
   */
  onSuccessfulSubmit() {
    Turbo.visit(window.location.href)
  }

  async showValidationError(message) {
    const el = document.querySelector("[data-controller='confirmation-modal']")
    const confirmationModal = this.application.getControllerForElementAndIdentifier(
      el,
      "confirmation-modal"
    )
    await confirmationModal.confirm("Validation Error", message, {
      showCancel: false,
      confirmText: "OK"
    })
  }
}
