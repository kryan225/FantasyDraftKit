/**
 * Utility functions for formatting data
 */

/**
 * Format a number as currency
 */
export function formatCurrency(value: number): string {
  return `$${value.toFixed(0)}`
}

/**
 * Format a decimal stat (like AVG, ERA, WHIP)
 */
export function formatDecimalStat(value: number | undefined, decimals: number = 3): string {
  if (value === undefined || value === null) return '-'
  return value.toFixed(decimals)
}

/**
 * Format a counting stat (like HR, R, RBI)
 */
export function formatCountingStat(value: number | undefined): string {
  if (value === undefined || value === null) return '-'
  return Math.round(value).toString()
}

/**
 * Format player positions array
 */
export function formatPositions(positions: string[]): string {
  return positions.join(', ')
}

/**
 * Calculate remaining roster spots for a team
 */
export function calculateRemainingSpots(
  currentRosterSize: number,
  totalRosterSpots: number
): number {
  return Math.max(0, totalRosterSpots - currentRosterSize)
}
