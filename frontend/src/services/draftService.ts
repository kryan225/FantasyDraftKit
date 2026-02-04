import { apiClient } from './api'
import type { DraftPick, AuctionValueBreakdown, ApiResponse } from '../types'

/**
 * Service for managing draft picks and auction logic
 * Handles recording picks, keeper management, and value calculations
 */
export const draftService = {
  /**
   * Fetch all draft picks for a league
   */
  async getDraftPicks(leagueId: number): Promise<DraftPick[]> {
    const response = await apiClient.get<ApiResponse<DraftPick[]>>(
      `/api/v1/leagues/${leagueId}/draft_picks`
    )
    return response.data.data
  },

  /**
   * Record a new draft pick
   */
  async createDraftPick(
    leagueId: number,
    teamId: number,
    playerId: number,
    price: number
  ): Promise<DraftPick> {
    const response = await apiClient.post<ApiResponse<DraftPick>>(
      `/api/v1/leagues/${leagueId}/draft_picks`,
      {
        draft_pick: {
          team_id: teamId,
          player_id: playerId,
          price,
        },
      }
    )
    return response.data.data
  },

  /**
   * Update a draft pick (e.g., correct a mistake)
   */
  async updateDraftPick(id: number, updates: Partial<DraftPick>): Promise<DraftPick> {
    const response = await apiClient.patch<ApiResponse<DraftPick>>(`/api/v1/draft_picks/${id}`, {
      draft_pick: updates,
    })
    return response.data.data
  },

  /**
   * Delete a draft pick (undo)
   */
  async deleteDraftPick(id: number): Promise<void> {
    await apiClient.delete(`/api/v1/draft_picks/${id}`)
  },

  /**
   * Get auction value breakdown for remaining players
   */
  async getValueBreakdown(leagueId: number): Promise<AuctionValueBreakdown[]> {
    const response = await apiClient.get<ApiResponse<AuctionValueBreakdown[]>>(
      `/api/v1/leagues/${leagueId}/value_breakdown`
    )
    return response.data.data
  },
}
