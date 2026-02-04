import { useState, useEffect } from 'react'
import { draftService } from '../services/draftService'
import type { DraftPick } from '../types'

/**
 * Custom hook for managing draft state
 * Handles recording picks and maintaining draft history
 */
export function useDraft(leagueId: number | null) {
  const [draftPicks, setDraftPicks] = useState<DraftPick[]>([])
  const [loading, setLoading] = useState(false)
  const [error, setError] = useState<string | null>(null)

  const fetchDraftPicks = async () => {
    if (!leagueId) {
      setDraftPicks([])
      return
    }

    setLoading(true)
    setError(null)
    try {
      const data = await draftService.getDraftPicks(leagueId)
      setDraftPicks(data)
    } catch (err) {
      setError(err instanceof Error ? err.message : 'Failed to load draft picks')
    } finally {
      setLoading(false)
    }
  }

  useEffect(() => {
    fetchDraftPicks()
  }, [leagueId])

  const recordPick = async (teamId: number, playerId: number, price: number) => {
    if (!leagueId) return

    try {
      const newPick = await draftService.createDraftPick(leagueId, teamId, playerId, price)
      setDraftPicks((prev) => [...prev, newPick])
      return newPick
    } catch (err) {
      throw new Error(err instanceof Error ? err.message : 'Failed to record pick')
    }
  }

  const undoPick = async (pickId: number) => {
    try {
      await draftService.deleteDraftPick(pickId)
      setDraftPicks((prev) => prev.filter((p) => p.id !== pickId))
    } catch (err) {
      throw new Error(err instanceof Error ? err.message : 'Failed to undo pick')
    }
  }

  return {
    draftPicks,
    loading,
    error,
    recordPick,
    undoPick,
    refetch: fetchDraftPicks,
  }
}
