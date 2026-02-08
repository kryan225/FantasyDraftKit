import { Controller } from "@hotwired/stimulus"
import { PositionEligibility } from "../utils/position_eligibility"

// Connects to data-controller="roster-move"
export default class extends Controller {
  static targets = ["positionCell"]

  connect() {
    this.selectedPlayer = null
    this.selectedPosition = null
  }

  selectPlayer(event) {
    const cell = event.currentTarget
    const playerId = cell.dataset.playerId
    const currentPosition = cell.dataset.currentPosition
    const playerPositions = cell.dataset.playerPositions

    // If clicking the same player, deselect
    if (this.selectedPlayer === playerId) {
      this.clearSelection()
      return
    }

    // Clear any previous selection
    this.clearSelection()

    // Set new selection
    this.selectedPlayer = playerId
    this.selectedPosition = currentPosition

    // Highlight eligible positions
    this.highlightEligiblePositions(playerPositions, currentPosition)
  }

  highlightEligiblePositions(playerPositions, currentPosition) {
    const positions = playerPositions.split(',').map(p => p.trim())

    this.positionCellTargets.forEach(cell => {
      const targetPosition = cell.dataset.position
      const isSamePosition = targetPosition === currentPosition

      // Skip the current position
      if (isSamePosition) return

      // Check if player is eligible for this position
      const isEligible = PositionEligibility.isPlayerEligible(positions, targetPosition)

      // Check if position has available slots (considering we're moving FROM current position)
      const hasAvailableSlot = this.hasAvailableSlot(targetPosition, currentPosition)

      if (isEligible && hasAvailableSlot) {
        cell.classList.add('available-move')
        cell.dataset.action = "click->roster-move#movePlayer"
      }
    })
  }

  hasAvailableSlot(targetPosition, currentPosition) {
    // Count how many slots are available for the target position
    const targetCells = this.positionCellTargets.filter(cell =>
      cell.dataset.position === targetPosition
    )

    // Count filled vs total slots
    const totalSlots = targetCells.length
    const filledSlots = targetCells.filter(cell =>
      cell.dataset.playerId && cell.dataset.playerId !== ""
    ).length

    // If moving FROM this position type, we free up a slot
    const isSamePositionType = targetPosition === currentPosition
    const effectiveFilledSlots = isSamePositionType ? filledSlots - 1 : filledSlots

    return effectiveFilledSlots < totalSlots
  }

  movePlayer(event) {
    const cell = event.currentTarget
    const newPosition = cell.dataset.position
    const newSlotIndex = cell.dataset.slotIndex

    if (!this.selectedPlayer || !this.selectedPosition) return

    // Build form data
    const formData = new FormData()
    formData.append("draft_pick[drafted_position]", newPosition)

    // Submit via fetch with Turbo
    fetch(`/draft_picks/${this.selectedPlayer}`, {
      method: "PATCH",
      headers: {
        "X-CSRF-Token": document.querySelector('meta[name="csrf-token"]').content,
        "Accept": "text/vnd.turbo-stream.html"
      },
      body: formData
    }).then(response => {
      if (response.ok) {
        return response.text()
      }
      throw new Error("Move failed")
    }).then(html => {
      // Turbo will handle the stream response
      Turbo.renderStreamMessage(html)
      this.clearSelection()
    }).catch(error => {
      console.error("Error moving player:", error)
      this.clearSelection()
    })
  }

  clearSelection() {
    this.selectedPlayer = null
    this.selectedPosition = null

    // Remove all highlighting and click handlers
    this.positionCellTargets.forEach(cell => {
      cell.classList.remove('available-move')
      cell.removeAttribute('data-action')
    })
  }

  disconnect() {
    this.clearSelection()
  }
}
