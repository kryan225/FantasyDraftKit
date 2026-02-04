import { apiClient } from './api'
import type { Player, PlayerFilters, ApiResponse } from '../types'

/**
 * Service for managing player data
 * Handles player search, filtering, and projection imports
 */
export const playerService = {
  /**
   * Fetch all players with optional filters
   */
  async getPlayers(filters?: PlayerFilters): Promise<Player[]> {
    const response = await apiClient.get<ApiResponse<Player[]>>('/api/v1/players', {
      params: filters,
    })
    return response.data.data
  },

  /**
   * Fetch a single player by ID
   */
  async getPlayer(id: number): Promise<Player> {
    const response = await apiClient.get<ApiResponse<Player>>(`/api/v1/players/${id}`)
    return response.data.data
  },

  /**
   * Import player projections from CSV
   */
  async importPlayers(file: File, leagueId: number): Promise<{ count: number; errors: string[] }> {
    const formData = new FormData()
    formData.append('file', file)
    formData.append('league_id', leagueId.toString())

    const response = await apiClient.post<ApiResponse<{ count: number; errors: string[] }>>(
      '/api/v1/players/import',
      formData,
      {
        headers: {
          'Content-Type': 'multipart/form-data',
        },
      }
    )
    return response.data.data
  },

  /**
   * Recalculate auction values for all undrafted players
   */
  async recalculateValues(leagueId: number): Promise<void> {
    await apiClient.post(`/api/v1/leagues/${leagueId}/recalculate_values`)
  },
}
