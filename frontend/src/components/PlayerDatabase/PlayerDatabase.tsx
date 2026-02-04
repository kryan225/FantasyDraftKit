import { usePlayers } from '../../hooks/usePlayers'
import LoadingSpinner from '../common/LoadingSpinner'
import ErrorMessage from '../common/ErrorMessage'
import './PlayerDatabase.css'

/**
 * Player database with search and filtering
 * Displays player projections and calculated values
 */
function PlayerDatabase() {
  const { players, loading, error, filters, setFilters, sortConfig, setSortConfig, refetch } =
    usePlayers({ isDrafted: false })

  if (loading) {
    return <LoadingSpinner message="Loading players..." />
  }

  if (error) {
    return <ErrorMessage message={error} onRetry={refetch} />
  }

  const handleSort = (field: string) => {
    setSortConfig({
      field: field as any,
      direction:
        sortConfig.field === field && sortConfig.direction === 'desc' ? 'asc' : 'desc',
    })
  }

  return (
    <div className="player-database-container">
      <div className="database-header">
        <h2>Player Database</h2>
        <div className="search-controls">
          <input
            type="text"
            className="input search-input"
            placeholder="Search players..."
            value={filters.searchTerm || ''}
            onChange={(e) => setFilters({ ...filters, searchTerm: e.target.value })}
          />
        </div>
      </div>

      <div className="player-table-container">
        <table className="player-table">
          <thead>
            <tr>
              <th onClick={() => handleSort('name')}>Name</th>
              <th onClick={() => handleSort('positions')}>Pos</th>
              <th onClick={() => handleSort('mlbTeam')}>Team</th>
              <th onClick={() => handleSort('calculatedValue')}>Value</th>
              <th onClick={() => handleSort('r')}>R</th>
              <th onClick={() => handleSort('hr')}>HR</th>
              <th onClick={() => handleSort('rbi')}>RBI</th>
              <th onClick={() => handleSort('sb')}>SB</th>
              <th onClick={() => handleSort('avg')}>AVG</th>
              <th onClick={() => handleSort('w')}>W</th>
              <th onClick={() => handleSort('k')}>K</th>
              <th onClick={() => handleSort('era')}>ERA</th>
              <th onClick={() => handleSort('whip')}>WHIP</th>
              <th onClick={() => handleSort('sv')}>SV</th>
            </tr>
          </thead>
          <tbody>
            {players.map((player) => (
              <tr key={player.id} className="player-row">
                <td className="player-name">{player.name}</td>
                <td>{player.positions.join(', ')}</td>
                <td>{player.mlbTeam}</td>
                <td className="value-cell">
                  ${player.calculatedValue?.toFixed(0) || '-'}
                </td>
                <td>{player.projections.r?.toFixed(0) || '-'}</td>
                <td>{player.projections.hr?.toFixed(0) || '-'}</td>
                <td>{player.projections.rbi?.toFixed(0) || '-'}</td>
                <td>{player.projections.sb?.toFixed(0) || '-'}</td>
                <td>{player.projections.avg?.toFixed(3) || '-'}</td>
                <td>{player.projections.w?.toFixed(0) || '-'}</td>
                <td>{player.projections.k?.toFixed(0) || '-'}</td>
                <td>{player.projections.era?.toFixed(2) || '-'}</td>
                <td>{player.projections.whip?.toFixed(2) || '-'}</td>
                <td>{player.projections.sv?.toFixed(0) || '-'}</td>
              </tr>
            ))}
          </tbody>
        </table>
      </div>

      {players.length === 0 && (
        <div className="empty-state">
          <p>No players found. Import player projections to get started.</p>
        </div>
      )}
    </div>
  )
}

export default PlayerDatabase
