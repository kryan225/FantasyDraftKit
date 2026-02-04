import { Outlet, Link, useLocation } from 'react-router-dom'
import './Layout.css'

/**
 * Main application layout with navigation
 * Provides consistent structure across all pages
 */
function Layout() {
  const location = useLocation()

  const isActive = (path: string) => {
    return location.pathname === path ? 'active' : ''
  }

  return (
    <div className="layout">
      <nav className="navbar">
        <div className="navbar-brand">
          <h1>⚾ Fantasy Draft Kit</h1>
        </div>
        <ul className="navbar-links">
          <li>
            <Link to="/" className={isActive('/')}>
              Draft Board
            </Link>
          </li>
          <li>
            <Link to="/players" className={isActive('/players')}>
              Players
            </Link>
          </li>
          <li>
            <Link to="/teams" className={isActive('/teams')}>
              Teams
            </Link>
          </li>
          <li>
            <Link to="/free-agents" className={isActive('/free-agents')}>
              Free Agents
            </Link>
          </li>
          <li>
            <Link to="/keepers" className={isActive('/keepers')}>
              Keepers
            </Link>
          </li>
          <li>
            <Link to="/settings" className={isActive('/settings')}>
              Settings
            </Link>
          </li>
        </ul>
      </nav>
      <main className="main-content">
        <Outlet />
      </main>
    </div>
  )
}

export default Layout
