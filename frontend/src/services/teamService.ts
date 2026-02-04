import { apiClient } from './api'
import type { Team, TeamCategoryStrength, ApiResponse } from '../types'

/**
 * Service for managing team data
 * Handles team rosters, budgets, and category analysis
 */
export const teamService = {
  /**
   * Fetch all teams in a league
   */
  async getTeams(leagueId: number): Promise<Team[]> {
    const response = await apiClient.get<ApiResponse<Team[]>>(`/api/v1/leagues/${leagueId}/teams`)
    return response.data.data
  },

  /**
   * Fetch a single team by ID
   */
  async getTeam(id: number): Promise<Team> {
    const response = await apiClient.get<ApiResponse<Team>>(`/api/v1/teams/${id}`)
    return response.data.data
  },

  /**
   * Create a new team
   */
  async createTeam(leagueId: number, name: string): Promise<Team> {
    const response = await apiClient.post<ApiResponse<Team>>(`/api/v1/leagues/${leagueId}/teams`, {
      team: { name },
    })
    return response.data.data
  },

  /**
   * Update team information
   */
  async updateTeam(id: number, updates: Partial<Team>): Promise<Team> {
    const response = await apiClient.patch<ApiResponse<Team>>(`/api/v1/teams/${id}`, {
      team: updates,
    })
    return response.data.data
  },

  /**
   * Delete a team
   */
  async deleteTeam(id: number): Promise<void> {
    await apiClient.delete(`/api/v1/teams/${id}`)
  },

  /**
   * Get category strengths/weaknesses for a team
   */
  async getCategoryAnalysis(teamId: number): Promise<TeamCategoryStrength[]> {
    const response = await apiClient.get<ApiResponse<TeamCategoryStrength[]>>(
      `/api/v1/teams/${teamId}/category_analysis`
    )
    return response.data.data
  },
}
