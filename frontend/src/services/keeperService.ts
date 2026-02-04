import { apiClient } from './api'
import type { KeeperHistory, DraftPick, ApiResponse } from '../types'

/**
 * Service for managing keeper history and rules
 * Enforces one-year keeper limits and handles keeper imports
 */
export const keeperService = {
  /**
   * Fetch keeper history for a league
   */
  async getKeeperHistory(leagueId: number): Promise<KeeperHistory[]> {
    const response = await apiClient.get<ApiResponse<KeeperHistory[]>>(
      `/api/v1/leagues/${leagueId}/keeper_history`
    )
    return response.data.data
  },

  /**
   * Import keepers from previous season
   */
  async importKeepers(
    leagueId: number,
    keepers: Array<{ team_id: number; player_id: number; price: number }>
  ): Promise<DraftPick[]> {
    const response = await apiClient.post<ApiResponse<DraftPick[]>>(
      `/api/v1/leagues/${leagueId}/import_keepers`,
      { keepers }
    )
    return response.data.data
  },

  /**
   * Check if a player is eligible to be kept by a team
   */
  async checkKeeperEligibility(
    leagueId: number,
    playerId: number,
    teamId: number
  ): Promise<{ eligible: boolean; reason?: string }> {
    const response = await apiClient.get<
      ApiResponse<{ eligible: boolean; reason?: string }>
    >(`/api/v1/leagues/${leagueId}/check_keeper_eligibility`, {
      params: { player_id: playerId, team_id: teamId },
    })
    return response.data.data
  },
}
