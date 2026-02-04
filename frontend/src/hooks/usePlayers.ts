import { useState, useEffect, useMemo } from 'react'
import { playerService } from '../services/playerService'
import type { Player, PlayerFilters, SortConfig } from '../types'

/**
 * Custom hook for managing player data with filtering and sorting
 * Implements client-side filtering for better UX after initial load
 */
export function usePlayers(initialFilters?: PlayerFilters) {
  const [players, setPlayers] = useState<Player[]>([])
  const [loading, setLoading] = useState(false)
  const [error, setError] = useState<string | null>(null)
  const [filters, setFilters] = useState<PlayerFilters>(initialFilters || {})
  const [sortConfig, setSortConfig] = useState<SortConfig>({
    field: 'calculatedValue',
    direction: 'desc',
  })

  const fetchPlayers = async () => {
    setLoading(true)
    setError(null)
    try {
      const data = await playerService.getPlayers(filters)
      setPlayers(data)
    } catch (err) {
      setError(err instanceof Error ? err.message : 'Failed to load players')
    } finally {
      setLoading(false)
    }
  }

  useEffect(() => {
    fetchPlayers()
  }, []) // Only fetch once, then filter client-side

  // Client-side filtering and sorting for better performance
  const filteredAndSortedPlayers = useMemo(() => {
    let result = [...players]

    // Apply filters
    if (filters.searchTerm) {
      const term = filters.searchTerm.toLowerCase()
      result = result.filter(
        (p) =>
          p.name.toLowerCase().includes(term) ||
          p.mlbTeam.toLowerCase().includes(term)
      )
    }

    if (filters.positions && filters.positions.length > 0) {
      result = result.filter((p) =>
        p.positions.some((pos) => filters.positions?.includes(pos))
      )
    }

    if (filters.isDrafted !== undefined) {
      result = result.filter((p) => p.isDrafted === filters.isDrafted)
    }

    // Apply sorting
    result.sort((a, b) => {
      const field = sortConfig.field
      let aVal: any
      let bVal: any

      if (field === 'name' || field === 'mlbTeam') {
        aVal = a[field]
        bVal = b[field]
      } else if (field === 'positions') {
        aVal = a.positions.join(',')
        bVal = b.positions.join(',')
      } else if (field === 'calculatedValue') {
        aVal = a.calculatedValue ?? -Infinity
        bVal = b.calculatedValue ?? -Infinity
      } else {
        aVal = a.projections[field] ?? 0
        bVal = b.projections[field] ?? 0
      }

      if (aVal < bVal) return sortConfig.direction === 'asc' ? -1 : 1
      if (aVal > bVal) return sortConfig.direction === 'asc' ? 1 : -1
      return 0
    })

    return result
  }, [players, filters, sortConfig])

  return {
    players: filteredAndSortedPlayers,
    loading,
    error,
    filters,
    setFilters,
    sortConfig,
    setSortConfig,
    refetch: fetchPlayers,
  }
}
