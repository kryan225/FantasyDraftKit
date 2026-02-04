import { apiClient } from './api'
import type { League, ApiResponse } from '../types'

/**
 * Service for managing league data
 * Handles all league-related API operations
 */
export const leagueService = {
  /**
   * Fetch all leagues
   */
  async getLeagues(): Promise<League[]> {
    const response = await apiClient.get<ApiResponse<League[]>>('/api/v1/leagues')
    return response.data.data
  },

  /**
   * Fetch a single league by ID
   */
  async getLeague(id: number): Promise<League> {
    const response = await apiClient.get<ApiResponse<League>>(`/api/v1/leagues/${id}`)
    return response.data.data
  },

  /**
   * Create a new league
   */
  async createLeague(league: Omit<League, 'id' | 'createdAt' | 'updatedAt'>): Promise<League> {
    const response = await apiClient.post<ApiResponse<League>>('/api/v1/leagues', { league })
    return response.data.data
  },

  /**
   * Update an existing league
   */
  async updateLeague(id: number, updates: Partial<League>): Promise<League> {
    const response = await apiClient.patch<ApiResponse<League>>(`/api/v1/leagues/${id}`, {
      league: updates,
    })
    return response.data.data
  },

  /**
   * Delete a league
   */
  async deleteLeague(id: number): Promise<void> {
    await apiClient.delete(`/api/v1/leagues/${id}`)
  },
}
