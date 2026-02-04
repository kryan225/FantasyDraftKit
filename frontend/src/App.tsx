import { Routes, Route } from 'react-router-dom'
import Layout from './components/common/Layout'
import DraftBoard from './components/DraftBoard/DraftBoard'
import PlayerDatabase from './components/PlayerDatabase/PlayerDatabase'
import TeamRosters from './components/TeamRoster/TeamRosters'
import FreeAgents from './components/FreeAgents/FreeAgents'
import KeeperManagement from './components/KeeperManagement/KeeperManagement'
import LeagueSettings from './components/LeagueSettings/LeagueSettings'
import './App.css'

function App() {
  return (
    <Routes>
      <Route path="/" element={<Layout />}>
        <Route index element={<DraftBoard />} />
        <Route path="players" element={<PlayerDatabase />} />
        <Route path="teams" element={<TeamRosters />} />
        <Route path="free-agents" element={<FreeAgents />} />
        <Route path="keepers" element={<KeeperManagement />} />
        <Route path="settings" element={<LeagueSettings />} />
      </Route>
    </Routes>
  )
}

export default App
