import { useState, useEffect } from 'react'
import { teamService } from '../services/teamService'
import type { Team } from '../types'

/**
 * Custom hook for managing team data for a league
 */
export function useTeams(leagueId: number | null) {
  const [teams, setTeams] = useState<Team[]>([])
  const [loading, setLoading] = useState(false)
  const [error, setError] = useState<string | null>(null)

  const fetchTeams = async () => {
    if (!leagueId) {
      setTeams([])
      return
    }

    setLoading(true)
    setError(null)
    try {
      const data = await teamService.getTeams(leagueId)
      setTeams(data)
    } catch (err) {
      setError(err instanceof Error ? err.message : 'Failed to load teams')
    } finally {
      setLoading(false)
    }
  }

  useEffect(() => {
    fetchTeams()
  }, [leagueId])

  return { teams, loading, error, refetch: fetchTeams }
}
