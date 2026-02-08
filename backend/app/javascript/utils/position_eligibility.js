/**
 * Position Eligibility Utility
 *
 * Centralized position eligibility logic for JavaScript controllers.
 * This mirrors the PositionEligibility Ruby concern to ensure consistent
 * behavior between backend and frontend.
 *
 * Eligibility Rules:
 * - UTIL: Can be filled by any batter (C, 1B, 2B, 3B, SS, OF)
 * - MI: Can be filled by middle infielders (2B, SS)
 * - CI: Can be filled by corner infielders (1B, 3B)
 * - Standard positions: Direct match required (C, 1B, 2B, 3B, SS, OF, SP, RP)
 * - BENCH: Can hold any player (batters and pitchers)
 */

export const PositionEligibility = {
  /**
   * Determines if a player with given positions can fill a specific roster position
   *
   * @param {Array<string>} playerPositions - Array of player's positions (e.g., ["2B", "SS"])
   * @param {string} targetPosition - The roster position to check (e.g., "UTIL", "MI")
   * @returns {boolean} true if player can fill the position, false otherwise
   */
  isPlayerEligible(playerPositions, targetPosition) {
    if (!Array.isArray(playerPositions)) {
      playerPositions = playerPositions.split(',').map(p => p.trim())
    }

    switch (targetPosition) {
      case "UTIL":
        // UTIL accepts any batter position
        return playerPositions.some(p => ["C", "1B", "2B", "3B", "SS", "OF"].includes(p))

      case "MI":
        // MI (Middle Infield) accepts 2B or SS
        return playerPositions.some(p => ["2B", "SS"].includes(p))

      case "CI":
        // CI (Corner Infield) accepts 1B or 3B
        return playerPositions.some(p => ["1B", "3B"].includes(p))

      case "BENCH":
        // BENCH accepts any player
        return true

      default:
        // Standard positions require direct match
        return playerPositions.includes(targetPosition)
    }
  },

  /**
   * Returns all positions a player is eligible to fill
   *
   * This includes their natural positions plus any flex positions they qualify for
   *
   * @param {Array<string>} playerPositions - Array of player's positions
   * @returns {Array<string>} Array of position names the player can fill
   */
  getEligiblePositions(playerPositions) {
    if (!Array.isArray(playerPositions)) {
      playerPositions = playerPositions.split(',').map(p => p.trim())
    }

    const eligible = [...playerPositions]

    // Add flex positions based on eligibility
    if (this.isPlayerEligible(playerPositions, "UTIL")) {
      eligible.push("UTIL")
    }
    if (this.isPlayerEligible(playerPositions, "MI")) {
      eligible.push("MI")
    }
    if (this.isPlayerEligible(playerPositions, "CI")) {
      eligible.push("CI")
    }
    // Everyone can go to bench
    eligible.push("BENCH")

    // Remove duplicates and return
    return [...new Set(eligible)]
  },

  /**
   * Position constants
   */
  BATTER_POSITIONS: ["C", "1B", "2B", "3B", "SS", "OF"],
  PITCHER_POSITIONS: ["SP", "RP"],
  FLEX_POSITIONS: ["UTIL", "MI", "CI"],

  get ALL_POSITIONS() {
    return [
      ...this.BATTER_POSITIONS,
      ...this.PITCHER_POSITIONS,
      ...this.FLEX_POSITIONS,
      "BENCH"
    ]
  }
}
