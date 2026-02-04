# CLAUDE.md - FantasyDraftKit Project Instructions

## 📝 MAINTAINING THIS FILE

**IMPORTANT:** You (Claude) MUST actively update this CLAUDE.md file as the project evolves.

### When to Update This File

Update this file whenever you:
- ✅ Complete a major feature or milestone
- ✅ Make architectural decisions that affect future work
- ✅ Implement new models, controllers, or API endpoints
- ✅ Change configuration files or environment setup
- ✅ Discover important context or constraints
- ✅ Solve significant bugs or issues
- ✅ Add new dependencies or technologies
- ✅ Make decisions about design patterns or approaches

### What to Document

Keep this file current with:
- **Progress Updates:** What's been completed, what's in progress
- **Implementation Decisions:** Why certain approaches were chosen
- **Known Issues:** Current bugs, limitations, or technical debt
- **Configuration Changes:** Updates to ports, environment variables, etc.
- **New Dependencies:** Gems, npm packages, or external services added
- **API Contract Changes:** New or modified endpoints
- **Important Context:** Anything future Claude sessions need to know

### How to Update

After completing significant work:
1. Edit the relevant sections of this CLAUDE.md file
2. Add new sections if the existing structure doesn't fit
3. Update timestamps in the "Project Status" section
4. Keep the "Current State" accurate and truthful

**The goal:** Future Claude sessions should be able to read this file and immediately understand the project's current state, constraints, and progress without having to re-discover context.

---

## CRITICAL: Non-Standard Port Requirements

⚠️ **EXTREMELY IMPORTANT** ⚠️

This project MUST use non-standard ports to avoid interfering with the developer's professional work projects. This is a hard requirement and violating it could disrupt active work environments.

### Required Port Assignments

**NEVER change these ports without explicit approval:**

- **PostgreSQL Database:** Port `5434` (NOT 5432)
- **Rails Backend API:** Port `3639` (NOT 3000)
- **React Frontend Dev Server:** Port `1147` (NOT 5173 or 3000)

### Configuration Files Using These Ports

When making changes, verify these files maintain correct ports:

1. **docker-compose.yml**
   - db service: `"5434:5432"`
   - backend service: `"3639:3000"`
   - frontend service: `"1147:5173"`

2. **backend/config/database.yml**
   - development URL: `postgres://fantasy_draft_kit:password@localhost:5434/fantasy_draft_kit_development`
   - test URL: `postgres://fantasy_draft_kit:password@localhost:5434/fantasy_draft_kit_test`

3. **docker-compose.yml (frontend environment)**
   - `VITE_API_URL: http://localhost:3639`

4. **frontend/src/services/api.ts** (if exists)
   - Base URL should reference port 3639

### Local Development Startup Commands

Always use these exact commands:

```bash
# Backend (Rails)
cd backend
bundle exec rails server -p 3639

# Frontend (Vite)
cd frontend
npm run dev -- --port 1147

# PostgreSQL
# Must be running on port 5434
# Check with: lsof -i :5434
```

### Verification Checklist

Before starting any service, verify ports are available:

```bash
# Check if ports are free
lsof -i :5434  # PostgreSQL - should be empty or show postgres
lsof -i :3639  # Backend - should be empty
lsof -i :1147  # Frontend - should be empty
```

---

## 📊 Project Status

**Last Updated:** 2026-02-04
**Current Phase:** Backend Complete - Frontend Setup Next

### Completed ✅
- CLAUDE.md created with project context and constraints
- Frontend fully scaffolded (24 TypeScript files, complete architecture)
- Rails API initialized with PostgreSQL configuration
- Docker compose configuration (ports: 5434, 3639, 1147)
- Frontend architecture follows SOLID principles
- Service layer, hooks, and components defined
- **Backend: Ruby 3.3.7 dependencies installed** ✅
- **Backend: PostgreSQL database created on port 5434** ✅
- **Backend: All 5 models generated with associations and validations** ✅
  - League (with has_many teams, draft_picks)
  - Team (with belongs_to league, budget management)
  - Player (with scopes for drafted/available, position filtering)
  - DraftPick (with callbacks for budget tracking)
  - KeeperHistory (with year-based tracking)
- **Backend: Database migrations run successfully** ✅
- **Backend: All API controllers generated and implemented** ✅
  - LeaguesController (CRUD + recalculate_values)
  - TeamsController (CRUD + category_analysis)
  - PlayersController (index, import CSV)
  - DraftPicksController (CRUD with auto pick numbering)
  - KeeperHistoriesController (index, import, eligibility check)
- **Backend: RESTful routes configured** ✅
- **Backend: CORS configured for port 1147** ✅
- **Backend: Rails server running on port 3639** ✅
- **Backend: API tested and working** ✅

### In Progress 🚧
- None currently

### Pending ⏳
- Frontend: Install npm dependencies (`npm install`)
- Frontend: Verify dev server starts on port 1147
- Frontend: Update API base URL to point to localhost:3639
- Integration: Test frontend-to-backend connectivity
- Feature: Implement player value calculation algorithm
- Feature: Implement category analysis aggregation
- Testing: Write RSpec tests for models and controllers

### Known Issues 🐛
- **Frontend dependencies installation blocked by network/registry issues**
  - Both `npm install` and `yarn install` fail to reach registry
  - Error: "An unexpected error occurred" when resolving packages
  - Workaround: User can try again later when network is stable
  - Alternative: Use Docker to build frontend container (handles deps internally)
- Value recalculation and category analysis have placeholder implementations (TODOs marked)
- No frontend dependencies installed yet (node_modules/ doesn't exist)

### Recent Decisions 🎯
- **2026-02-03:** Decided to prioritize local development over Docker (YAGNI principle)
  - Rationale: Docker adds complexity; local dev is faster for iteration
  - Docker can be added later for deployment
- **2026-02-03:** Backend implementation prioritized before frontend
  - Rationale: Backend is empty; frontend is already architected
  - Once APIs exist, integration will be straightforward
- **2026-02-04:** Updated Ruby version from 3.3.10 to 3.3.7
  - Rationale: User already has 3.3.7 installed; Rails 8.1.2 compatible
  - Avoided 10-minute Ruby compilation time
- **2026-02-04:** Used Docker only for PostgreSQL database
  - Rationale: Keeps work database isolated on port 5434
  - Backend and frontend run natively for faster development
- **2026-02-04:** Added comprehensive model validations and callbacks
  - DraftPick automatically manages player drafted status
  - DraftPick automatically manages team budget deductions
  - Team automatically sets initial budget from league settings
  - Following Single Responsibility Principle

### Next Steps →
1. **Resolve frontend dependency installation**
   - Wait for network/registry to stabilize
   - Try `npm install` or `yarn install` again
   - Or use Docker: `docker-compose up frontend`
2. Start frontend dev server on port 1147: `npm run dev -- --port 1147`
3. Test full-stack integration (backend already running on 3639)
4. Create a test league with teams via frontend UI
5. Import sample player data via CSV
6. Test draft pick functionality end-to-end
7. Implement value calculation algorithm
8. Implement category analysis aggregation

### Recent Commits 📝
- **2026-02-04 (commit 31f3399):** Backend implementation complete
  - 130 files changed, 5102 insertions
  - All models, controllers, routes, migrations complete
  - Rails server tested and working on port 3639
  - CORS configured, gitignore files added
  - Pushed to GitHub successfully

---

## Project Architecture Overview

### Technology Stack

**Backend:**
- Ruby on Rails 8.1.2 (API-only mode)
- PostgreSQL 16
- Gems: rack-cors, rspec-rails, factory_bot_rails

**Frontend:**
- React 18.3.1 with TypeScript (strict mode)
- Vite 5.4 (build tool)
- React Router 6.22
- Axios for API calls

### Project Structure

```
FantasyDraftKit/
├── backend/              # Rails API
│   ├── app/
│   │   ├── models/      # Data models (empty - needs implementation)
│   │   └── controllers/ # API controllers (empty - needs implementation)
│   ├── config/
│   │   ├── database.yml # PostgreSQL config (PORT 5434)
│   │   └── routes.rb    # API routes (needs implementation)
│   └── Gemfile
├── frontend/            # React + TypeScript
│   ├── src/
│   │   ├── types/       # TypeScript interfaces
│   │   ├── services/    # API client layer (port 3639)
│   │   ├── hooks/       # Custom React hooks
│   │   ├── components/  # UI components
│   │   └── utils/       # Formatters, helpers
│   └── package.json
├── docker-compose.yml   # ALL PORTS DEFINED HERE
└── SETUP_STATUS.md      # Current implementation status
```

---

## Development Philosophy for This Project

### Current State: Greenfield Development

This project is in **early development** with:
- Backend models/controllers NOT yet implemented
- Frontend fully scaffolded but dependencies not installed
- Database schema NOT yet created
- API endpoints NOT yet defined

### Prioritize Local Development Over Docker

**Current Strategy (agreed with developer):**
1. Get Rails running locally on port 3639
2. Get React running locally on port 1147
3. Build features and iterate quickly
4. Docker can be added later for deployment

**Rationale:**
- Local development is faster for iteration
- Docker adds complexity we don't need yet (YAGNI)
- Easier debugging and hot-reloading
- Docker setup was causing issues

### Code Quality Standards

Follow all principles from the global CLAUDE.md:
- SOLID principles for all code
- DRY, KISS, YAGNI
- Testability first
- Security-conscious (sanitize inputs, avoid SQL injection, XSS)
- Clear separation of concerns

---

## Backend Implementation Requirements

### Data Models to Implement

Based on `SETUP_STATUS.md`, these models need to be created:

1. **League**
   - name:string
   - team_count:integer
   - auction_budget:integer
   - keeper_limit:integer
   - roster_config:jsonb

2. **Team**
   - league:references
   - name:string
   - budget_remaining:integer

3. **Player**
   - name:string
   - positions:string
   - mlb_team:string
   - projections:jsonb
   - calculated_value:decimal
   - is_drafted:boolean

4. **DraftPick**
   - league:references
   - team:references
   - player:references
   - price:integer
   - is_keeper:boolean
   - pick_number:integer

5. **KeeperHistory**
   - player:references
   - team:references
   - year:integer
   - price:integer

### API Endpoints Required

The frontend expects these RESTful endpoints on port **3639**:

**Leagues:**
- `GET /api/v1/leagues`
- `GET /api/v1/leagues/:id`
- `POST /api/v1/leagues`
- `PATCH /api/v1/leagues/:id`
- `DELETE /api/v1/leagues/:id`

**Teams:**
- `GET /api/v1/leagues/:league_id/teams`
- `GET /api/v1/teams/:id`
- `POST /api/v1/leagues/:league_id/teams`
- `GET /api/v1/teams/:id/category_analysis`

**Players:**
- `GET /api/v1/players`
- `POST /api/v1/players/import` (CSV upload)
- `POST /api/v1/leagues/:id/recalculate_values`

**Draft Picks:**
- `GET /api/v1/leagues/:league_id/draft_picks`
- `POST /api/v1/leagues/:league_id/draft_picks`
- `PATCH /api/v1/draft_picks/:id`
- `DELETE /api/v1/draft_picks/:id`

**Keepers:**
- `GET /api/v1/leagues/:league_id/keeper_history`
- `POST /api/v1/leagues/:league_id/import_keepers`
- `GET /api/v1/leagues/:league_id/check_keeper_eligibility`

---

## Frontend Implementation Notes

### Architecture Principles Applied

The frontend was scaffolded following best practices:

**Service Layer Pattern:**
- All API calls go through `src/services/`
- Services abstract away Axios details
- Centralized error handling in `api.ts`

**Custom Hooks Pattern:**
- Data-fetching hooks in `src/hooks/`
- Provide `{ data, loading, error, refetch }` interface
- Keep components clean and UI-focused

**Component Organization:**
- Feature components in dedicated directories
- Common/reusable components separated
- CSS co-located with components

### Frontend Base URL Configuration

The frontend MUST point to backend on **port 3639**.

Check these locations:
- `frontend/src/services/api.ts` - Axios baseURL
- `.env` or `.env.local` - VITE_API_URL=http://localhost:3639

---

## Testing Strategy

### Backend Testing
- Use RSpec for model and controller tests
- Factory Bot for test data generation
- Test API endpoints with request specs

### Frontend Testing
- Jest with React Testing Library configured
- Test components in isolation
- Mock API calls in tests

---

## Security Considerations

**Fantasy Baseball Draft Kit** handles:
- League settings and configurations
- Player projections (potentially proprietary)
- Draft history and keeper data

**Security Requirements:**
- Validate all user inputs (especially CSV uploads)
- Sanitize data before database insertion
- Use parameterized queries (Rails does this by default)
- CORS configured via rack-cors (already in Gemfile)
- No authentication yet - consider adding if app goes multi-user

---

## Git Workflow

**Current Status:** All work is untracked (not committed)

**Before Committing:**
- Ensure `.gitignore` excludes sensitive files
- Review `backend/.gitignore` and `frontend/.gitignore`
- Don't commit `.env` files, `node_modules/`, or database files

---

## Quick Reference Commands

### Start Backend Locally (Port 3639)
```bash
cd /Users/ryan.kleinberg/src/FantasyDraftKit/backend
bundle install
rails db:create
rails db:migrate
rails server -p 3639
```

### Start Frontend Locally (Port 1147)
```bash
cd /Users/ryan.kleinberg/src/FantasyDraftKit/frontend
npm install  # or yarn install
npm run dev -- --port 1147
```

### Access Application
- Frontend: http://localhost:1147
- Backend API: http://localhost:3639
- Database: localhost:5434

---

## Common Issues and Solutions

### Issue: Port Already in Use
```bash
# Find process using port
lsof -i :<port_number>

# Kill process if needed
kill -9 <PID>
```

### Issue: Database Connection Failed
- Verify PostgreSQL is running on port 5434
- Check `backend/config/database.yml` has correct port
- Ensure database exists: `rails db:create`

### Issue: Frontend Can't Reach Backend
- Verify Rails is running on port 3639
- Check CORS configuration in backend
- Verify `VITE_API_URL` environment variable

---

## Future Enhancements (Post-MVP)

- User authentication (if multi-user support needed)
- Real-time draft updates (WebSockets or Server-Sent Events)
- Advanced analytics and visualizations
- Export functionality for draft results
- Mobile-responsive design improvements
- Docker deployment configuration (after local dev stable)

---

## Contact and Context

- **Developer:** Uses this repo for personal fantasy baseball drafts
- **Work Constraint:** Must not interfere with professional development work (hence unique ports)
- **Development Stage:** Early greenfield - backend needs implementation
- **Priority:** Get working app locally first, optimize later
