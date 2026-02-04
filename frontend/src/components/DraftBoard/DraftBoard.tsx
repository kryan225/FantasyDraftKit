import { useState } from 'react'
import { useTeams } from '../../hooks/useTeams'
import { useDraft } from '../../hooks/useDraft'
import LoadingSpinner from '../common/LoadingSpinner'
import ErrorMessage from '../common/ErrorMessage'
import './DraftBoard.css'

/**
 * Main draft board component
 * Displays real-time auction tracking grid
 */
function DraftBoard() {
  // TODO: Get from context or route params
  const [leagueId] = useState<number | null>(null)
  const { teams, loading: teamsLoading, error: teamsError, refetch: refetchTeams } = useTeams(leagueId)
  const { draftPicks, loading: draftLoading, error: draftError, refetch: refetchDraft } = useDraft(leagueId)

  if (teamsLoading || draftLoading) {
    return <LoadingSpinner message="Loading draft board..." />
  }

  if (teamsError || draftError) {
    return (
      <ErrorMessage
        message={teamsError || draftError || 'Failed to load draft board'}
        onRetry={() => {
          refetchTeams()
          refetchDraft()
        }}
      />
    )
  }

  if (!leagueId) {
    return (
      <div className="draft-board-container">
        <div className="empty-state">
          <h2>No League Selected</h2>
          <p>Please create or select a league from the settings page to begin drafting.</p>
        </div>
      </div>
    )
  }

  return (
    <div className="draft-board-container">
      <div className="draft-board-header">
        <h2>Draft Board</h2>
        <div className="draft-stats">
          <span>Teams: {teams.length}</span>
          <span>Picks: {draftPicks.length}</span>
        </div>
      </div>

      <div className="draft-board-grid">
        {teams.map((team) => (
          <div key={team.id} className="team-column">
            <div className="team-header">
              <h3>{team.name}</h3>
              <span className="budget">${team.budgetRemaining}</span>
            </div>
            <div className="team-roster">
              {draftPicks
                .filter((pick) => pick.teamId === team.id)
                .map((pick) => (
                  <div key={pick.id} className="roster-pick">
                    <span className="player-name">{pick.player?.name}</span>
                    <span className="pick-price">${pick.price}</span>
                  </div>
                ))}
            </div>
          </div>
        ))}
      </div>
    </div>
  )
}

export default DraftBoard
