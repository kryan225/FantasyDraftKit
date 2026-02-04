import { useState, useEffect } from 'react'
import { leagueService } from '../services/leagueService'
import type { League } from '../types'

/**
 * Custom hook for managing league state
 * Provides loading states and error handling
 */
export function useLeague(leagueId: number | null) {
  const [league, setLeague] = useState<League | null>(null)
  const [loading, setLoading] = useState(false)
  const [error, setError] = useState<string | null>(null)

  useEffect(() => {
    if (!leagueId) {
      setLeague(null)
      return
    }

    const fetchLeague = async () => {
      setLoading(true)
      setError(null)
      try {
        const data = await leagueService.getLeague(leagueId)
        setLeague(data)
      } catch (err) {
        setError(err instanceof Error ? err.message : 'Failed to load league')
      } finally {
        setLoading(false)
      }
    }

    fetchLeague()
  }, [leagueId])

  return { league, loading, error, refetch: () => leagueId && setLeague(null) }
}

/**
 * Hook for managing all leagues
 */
export function useLeagues() {
  const [leagues, setLeagues] = useState<League[]>([])
  const [loading, setLoading] = useState(false)
  const [error, setError] = useState<string | null>(null)

  const fetchLeagues = async () => {
    setLoading(true)
    setError(null)
    try {
      const data = await leagueService.getLeagues()
      setLeagues(data)
    } catch (err) {
      setError(err instanceof Error ? err.message : 'Failed to load leagues')
    } finally {
      setLoading(false)
    }
  }

  useEffect(() => {
    fetchLeagues()
  }, [])

  return { leagues, loading, error, refetch: fetchLeagues }
}
