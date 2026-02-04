# Fantasy Baseball Draft Kit - Frontend

React + TypeScript frontend for managing fantasy baseball auction drafts with keeper support.

## Tech Stack

- **React 18** - UI library
- **TypeScript** - Type safety
- **Vite** - Build tool and dev server
- **React Router** - Client-side routing
- **Axios** - HTTP client

## Project Structure

```
src/
├── components/       # React components organized by feature
│   ├── common/      # Shared/reusable components
│   ├── DraftBoard/  # Draft board view
│   ├── PlayerDatabase/ # Player search and filtering
│   ├── TeamRoster/  # Team roster management
│   ├── FreeAgents/  # Free agent board
│   ├── KeeperManagement/ # Keeper import and rules
│   └── LeagueSettings/   # League configuration
├── services/        # API client and service layer
├── hooks/          # Custom React hooks
├── types/          # TypeScript type definitions
├── utils/          # Helper functions
├── App.tsx         # Main app component with routing
└── main.tsx        # Application entry point
```

## Design Principles

This codebase follows SOLID principles and emphasizes:

- **Single Responsibility**: Each component, hook, and service has one clear purpose
- **Dependency Inversion**: Components depend on service abstractions, not implementations
- **Interface Segregation**: Type definitions are specific and focused
- **Testability**: Logic is separated from UI for easier testing

## Development

### Install Dependencies

```bash
npm install
```

### Run Development Server

```bash
npm run dev
```

The app will be available at `http://localhost:5173`

### Build for Production

```bash
npm run build
```

### Run Tests

```bash
npm test
```

## API Integration

The frontend communicates with the Rails backend API via the service layer in `src/services/`.

All API calls are made through service modules that handle:
- Request/response transformation
- Error handling
- Type safety

The base API URL is configured via the `VITE_API_URL` environment variable (default: `http://localhost:3639`)

## Docker

The frontend is containerized and runs alongside the backend. See the root `docker-compose.yml` for configuration.

```bash
# From project root
docker-compose up frontend
```

## Key Features

1. **Draft Board** - Real-time auction tracking grid
2. **Player Database** - Searchable player projections with calculated values
3. **Team Rosters** - View budgets and positional needs
4. **Free Agents** - Live value recalculation as draft progresses
5. **Keeper Management** - Import and validate keeper selections
6. **League Settings** - Configure league parameters

## Custom Hooks

The app uses custom React hooks for data fetching and state management:

- `useLeague()` - Fetch and manage league data
- `useTeams()` - Fetch and manage team data
- `usePlayers()` - Fetch, filter, and sort players
- `useDraft()` - Manage draft picks and history

These hooks provide consistent loading states, error handling, and refetch capabilities.
