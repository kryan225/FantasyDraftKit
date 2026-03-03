# CLAUDE.md - FantasyDraftKit Project Instructions


## CRITICAL: Non-Standard Port Requirements

⚠️ **EXTREMELY IMPORTANT** ⚠️

This project MUST use non-standard ports to avoid interfering with the developer's professional work projects. This is a hard requirement and violating it could disrupt active work environments.

### Required Port Assignments

**NEVER change these ports without explicit approval:**

- **PostgreSQL Database:** Port `5434` (NOT 5432)
- **Rails Application (Backend + Frontend):** Port `3639` (NOT 3000)
- **Port 1147:** Reserved but not currently used (was planned for React frontend)

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
# Backend (Rails with Hotwire frontend)
cd backend
bundle exec rails server -p 3639

# PostgreSQL
# Must be running on port 5434 (Docker container)
# Check with: lsof -i :5434
# Start if needed: docker-compose up -d db

# Access the application
# Web UI: http://localhost:3639/
# API: http://localhost:3639/api/v1/*
```

### Verification Checklist

Before starting any service, verify ports are available:

```bash
# Check if ports are free
lsof -i :5434  # PostgreSQL - should show postgres/docker
lsof -i :3639  # Rails app - should be empty or show ruby
```

---

## 📊 Project Status

**Last Updated:** 2026-02-13
**Current Phase:** Full-Stack Application - Production Ready with Comprehensive Testing


### In Progress 🚧
- None currently

### Pending ⏳
- Feature: Add Stimulus controllers for enhanced interactivity (drag-drop, live updates)
- Feature: Implement player value calculation algorithm
- Feature: Implement category analysis aggregation
- Feature: Use ConfirmationModal for delete confirmations and destructive actions
- Testing: Write system tests for DraftModal validation (requires complex setup)
- Testing: Write RSpec unit tests for models (Player, League, Team, DraftPick)
- Testing: Write request specs for API endpoints
- Testing: Add system tests for full draft workflow
- Enhancement: Add more ConfirmationModal options (icons, colors, custom buttons)

### Known Issues 🐛
- Value recalculation and category analysis have placeholder implementations (TODOs marked)
- League creation form not yet implemented (only index and show views exist)
- Pre-existing auto-generated request spec stubs need implementation (23 failures in scaffold specs)
- Jest test files exist but can't run without npm (kept as documentation)

### Recent Decisions 🎯
- **2026-02-13:** Allowed pitchers to play UTIL position
  - Rationale: League rules permit any player (including SP/RP) in UTIL slot
  - Updated Ruby concern, JavaScript utility, and value calculator (all three eligibility implementations)
  - Pitchers now get UTIL as a flex position for roster move lookahead
  - Affects draft modal position options, nomination algorithm, and team needs matrix
- **2026-02-13:** Added Nomination Strategy Suggestions to Draft Analyzer
  - Rationale: Strategic nominations are a key auction draft skill — app should guide users
  - Algorithm weights four factors: opponent demand, position scarcity, player value, user's need
  - Reuses existing position fill rates and team_can_draft_position? lookahead
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
- **2026-02-04:** Chose Hotwire over React for frontend
  - Rationale: npm registry blocked due to shai-hulud worm security restrictions
  - Hotwire uses importmap-rails, avoiding npm dependency entirely
  - Keeps full-stack Rails simpler with no separate frontend build process
  - Maintains dual-mode architecture: HTML views for web UI, JSON API for future clients
  - Changed config.api_only = false, created Api::V1::BaseController for API-only JSON
- **2026-02-07:** Created LeagueResolvable concern for DRY league resolution
  - Rationale: DraftBoardController needed league without league_id in URL
  - Follows Single Responsibility Principle - one module handles league resolution
  - Implements KISS principle - auto-resolves single league for better UX
  - Makes pattern reusable across future web UI controllers
  - Fixed Player.available scope to handle nil values (not just false)
- **2026-02-07:** Implemented Draft Modal with Turbo Streams
  - Rationale: Real-time draft updates without page reload improves UX
  - Used Turbo Streams for partial page updates (draft list, available players, team budgets)
  - Added roster validation to prevent invalid draft picks
  - Undo functionality with Turbo::FrameMissingError handling
- **2026-02-07:** Created BaseModalController pattern for reusable modals
  - Rationale: Multiple modals needed across app (draft, edit player, future features)
  - Follows Open/Closed Principle - base class provides core behavior, extended by specific modals
  - Reduces duplication and ensures consistent modal UX
  - Used Stimulus controller inheritance for code reuse
- **2026-02-08:** Fixed EditPlayerModal controller scope issue
  - Problem: Clicking player names sent network request but no UI response
  - Root Cause: Controller scoped to modal div only, player links were outside scope
  - Solution: Moved data-controller to <body> tag, modal HTML to layout
  - This makes modal available globally and all player links work correctly
  - Lesson: Stimulus controller scope must wrap all elements that trigger actions
- **2026-02-08:** Set up Cuprite for JavaScript-capable system testing
  - Rationale: Frontend bug wasn't caught because Jest tests couldn't run (no npm)
  - Chose Cuprite over Selenium for speed and simplicity (KISS principle)
  - No driver binary management needed (Chrome DevTools Protocol)
- **2026-02-08:** Made Data Control and Players pages league-scoped
  - Rationale: These features operate on league-specific data, should be accessed from league context
  - Removed from global navigation to reduce clutter and make navigation more intuitive
  - Follows same pattern as Draft Board and Draft Analyzer (league-scoped features)
  - Standalone routes kept for single-league auto-resolution
- **2026-02-08:** Changed player database default filter to "Available Only"
  - Rationale: During draft, users primarily care about available players, not drafted ones
  - Reduces cognitive load - immediately shows actionable players
  - Explicit "All Players" and "Drafted Only" options still available
  - Uses `params.key?(:drafted)` to distinguish no-param vs empty-string (important for UX)
- **2026-02-08:** Created comprehensive test suite for draft board player database
  - Rationale: Player database is critical feature - bugs here directly impact draft experience
  - 42 tests cover all filter combinations, sorting, edge cases, parameter persistence
  - Tests validate the "Available Only" default behavior and "All Players" override
  - Protects against regressions as feature evolves
  - Fixed player factory projections bug discovered during testing
  - 2-3x faster than Selenium, perfect for local development iteration
  - Validates actual browser behavior, not just HTML structure
  - Critical gap addressed: Now have executable frontend tests that catch real bugs
- **2026-02-08:** Created ConfirmationModal to replace JavaScript alert()
  - Rationale: alert() provides poor UX and doesn't match polished application
  - Follows same pattern as BaseModalController (Open/Closed, DRY principles)
  - Promise-based API enables clean async/await validation flow
  - Removed HTML5 required attributes to allow JavaScript validation control
  - Better UX: styled modals with clear messaging instead of browser alerts
  - Reusable across entire application for any confirmation needs

### Next Steps →
1. ✅ ~~Test the web UI at http://localhost:3639/~~ - Working and fully functional
2. ✅ ~~Create leagues and teams through the web interface~~ - Implemented with seed data
3. ✅ ~~Import player projections via CSV upload~~ - Data Control page with CSV import
4. Implement league creation form (currently only show/index work)
5. Add Stimulus controllers for enhanced interactivity (already have several: modals, collapsible, scroll-memory, row-actions)
6. Implement player value calculation algorithm (placeholder in place)
7. Implement category analysis aggregation (placeholder in place)
8. ✅ ~~Add form validations and error handling in views~~ - ConfirmationModal for all validations
9. ✅ ~~Add RSpec tests for models, controllers, and views~~ - Comprehensive test coverage:
   - Draft Board: 42 passing tests
   - Draft Analyzer: 32 passing tests
   - BaseModalController: 30+ passing tests
   - EditPlayerModal: 15+ passing tests
   - ConfirmationModal: 4+ passing tests
   - UndoPick: 3+ passing tests
   - LeagueResolvable: 15 passing tests
   - Position Eligibility: 39 passing tests
   - DraftPick Model: 16 passing tests
   - **Total: 200+ passing tests**


---

## Project Architecture Overview

### Technology Stack

**Backend:**
- Ruby on Rails 8.1.2 (full-stack mode with API support)
- PostgreSQL 16
- Gems: rack-cors, rspec-rails, factory_bot_rails

**Frontend:**
- Hotwire (Turbo + Stimulus) for interactive web UI
- Importmap-rails for JavaScript module management
- Sprockets asset pipeline for CSS
- ERB templates for server-rendered HTML

**Testing:**
- RSpec for unit and system tests
- Capybara + Cuprite for JavaScript-enabled browser testing
- FactoryBot for test data generation
- Screenshot capture on test failures
- Fast test execution (~3 seconds for system tests)

**Architecture:**
- Dual-mode: HTML views for web UI, JSON API for future mobile/external clients
- ApplicationController (ActionController::Base) for HTML views
- Api::V1::BaseController (ActionController::API) for JSON endpoints

### Project Structure

```
FantasyDraftKit/
├── backend/              # Rails full-stack application
│   ├── app/
│   │   ├── models/      # League, Team, Player, DraftPick, KeeperHistory
│   │   ├── controllers/
│   │   │   ├── api/v1/  # JSON API controllers (API-only mode)
│   │   │   └── *.rb     # Web UI controllers (leagues, players, teams, draft_board)
│   │   ├── views/       # ERB templates for web UI
│   │   ├── javascript/  # Stimulus controllers
│   │   └── assets/      # CSS stylesheets
│   ├── config/
│   │   ├── database.yml # PostgreSQL config (PORT 5434)
│   │   ├── routes.rb    # Routes for both web UI and API
│   │   └── importmap.rb # JavaScript module management
│   └── Gemfile
├── frontend/            # React + TypeScript (NOT USED - kept for reference)
│   └── [scaffolded but not installed due to npm restrictions]
├── docker-compose.yml   # PostgreSQL on port 5434
├── CLAUDE.md            # This file - project documentation
└── DRAFT_ANALYZER.md    # Draft analyzer feature documentation and roadmap
```

---

## Development Philosophy for This Project

### Current State: Functional Application

This project is now **functional** with:
- Backend models, controllers, and API endpoints fully implemented
- Database schema created with migrations
- Hotwire frontend providing web UI for all core features
- Dual-mode architecture: HTML views + JSON API working together
- Application running on port 3639
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

   **Default Roster Configuration** (22 total slots):
   ```ruby
   {
     "C" => 2,      # Catchers
     "1B" => 1,     # First Base
     "2B" => 1,     # Second Base
     "3B" => 1,     # Third Base
     "SS" => 1,     # Shortstop
     "MI" => 1,     # Middle Infield (2B or SS eligible)
     "CI" => 1,     # Corner Infield (1B or 3B eligible)
     "OF" => 5,     # Outfielders
     "UTIL" => 1,   # Utility (any player — batters and pitchers)
     "SP" => 5,     # Starting Pitchers
     "RP" => 3,     # Relief Pitchers
     "BENCH" => 0   # No bench spots
   }
   ```

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

**CRITICAL:** This project follows the **Testing Pyramid** model for optimal test coverage and speed.

### Testing Pyramid Philosophy

```
      E2E/System Tests (~10%)  ← Slow, expensive, critical user journeys only
     /                        \
    /  Integration Tests (~30%)  ← Medium speed, test component interactions
   /                              \
  /   Unit Tests (~60%)            ← Fast, test business logic in isolation
 /__________________________________\
```

### Layer 1: Unit Tests (Base - Fast & Plentiful)

**Purpose:** Test business logic in isolation with no external dependencies

**What to test:**
- Model validations, scopes, and methods
- Concerns and utility modules (e.g., `PositionEligibility`)
- Service objects and business logic
- Helper methods and calculations

**Examples:**
- `spec/lib/position_eligibility_spec.rb` - Position eligibility rules (50 tests)
- `spec/models/player_spec.rb` - Player validations and scopes
- `spec/models/draft_pick_spec.rb` - Callbacks and associations

**Characteristics:**
- Run in < 1 second for 50+ examples
- No database hits (use `build` instead of `create` when possible)
- No HTTP requests, no JavaScript, no browser
- Test pure Ruby logic

### Layer 2: Integration Tests (Middle - Medium Speed)

**Purpose:** Test that components work together correctly

**What to test:**
- Controller actions and HTTP responses
- Database queries and ActiveRecord relationships
- API endpoints with JSON responses
- Concerns integrated into controllers

**Examples:**
- `spec/requests/draft_analyzer_spec.rb` - Controller integration with database
- `spec/controllers/draft_board_controller_spec.rb` - Controller behavior
- `spec/requests/api/v1/*_spec.rb` - API endpoint testing

**Characteristics:**
- Run in 1-3 seconds for 20+ examples
- Use database (with transactions/rollbacks)
- No JavaScript, no browser
- Test HTTP request/response cycle

### Layer 3: E2E/System Tests (Top - Slow & Selective)

**Purpose:** Test critical user journeys that require JavaScript

**What to test (ONLY):**
- Complete user workflows (draft a player end-to-end)
- JavaScript interactions (modals, dynamic UI updates)
- Turbo Stream updates
- Critical business flows

**What NOT to test:**
- Low-level logic (belongs in unit tests)
- Every possible UI state
- Position eligibility rules (tested in unit tests)

**Examples:**
- `spec/system/roster_management_spec.rb` - Click-to-move player workflow
- `spec/system/edit_player_modal_spec.rb` - Modal interactions
- `spec/system/confirmation_modal_spec.rb` - Confirmation dialog flow

**Characteristics:**
- Run in 30-90 seconds for 3-5 examples
- Use Cuprite (headless Chrome)
- Full JavaScript execution
- Expensive - keep these minimal

### Current Test Distribution

**As of 2026-02-07:**
```
Unit Tests:        75 examples in 0.6s   (60% coverage) ✅
Integration Tests: 25 examples in 1.2s   (30% coverage) ✅
System Tests:      ~8 examples in 60s    (10% coverage) ✅
```

### Testing Best Practices

**DO:**
- ✅ Write unit tests for ALL business logic
- ✅ Test edge cases in unit tests (fast and cheap)
- ✅ Use integration tests to verify components work together
- ✅ Write ONE system test per user journey
- ✅ Keep system tests high-level (click button → see result)

**DON'T:**
- ❌ Test position eligibility rules in system tests (too slow)
- ❌ Test every CSS class appearing (unit test the logic instead)
- ❌ Write system tests for things that don't need JavaScript
- ❌ Test internal implementation details in integration tests

### Running Tests

```bash
# Fast unit tests (run these frequently during development)
bundle exec rspec spec/models/ spec/lib/ --format progress

# Integration tests (run before committing)
bundle exec rspec spec/requests/ spec/controllers/ --format progress

# System tests (run before pushing or for full QA)
bundle exec rspec spec/system/ --format documentation

# All non-system tests (fast feedback loop)
bundle exec rspec --exclude-pattern "spec/system/**/*_spec.rb"
```

### Backend Testing Tools
- RSpec for test framework
- Factory Bot for test data generation
- Cuprite for JavaScript-capable system tests (headless Chrome)
- SimpleCov for code coverage (if added)

### Frontend Testing (Hotwire)
- Stimulus controllers tested via system tests
- JavaScript utilities (like `position_eligibility.js`) should have unit tests if complex logic
- Turbo Stream responses tested via integration tests

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

## Git Workflow and Commit Strategy

### Core Principles

**You (Claude) MUST follow these git practices:**

1. **Meaningful, Reviewable Commits**
   - Each commit should represent a complete, logical unit of work
   - The commit should be reviewable - a human should be able to understand what changed and why
   - Commit messages should clearly describe WHAT changed and WHY

2. **Bundle Related Changes**
   - Group related changes into the same commit
   - Example: If you add a new controller method, its tests, and update routes, commit them together
   - This provides context and makes it easier to understand the change
   - Example: If you fix a bug in multiple places that are all part of the same fix, commit them together

3. **Proactive Committing**
   - **YOU MUST proactively commit to main when a significant relevant change is made**
   - Don't wait to be asked - commit when work is complete
   - Significant changes include:
     - ✅ New features or functionality complete and tested
     - ✅ Bug fixes complete and tested
     - ✅ Refactoring complete
     - ✅ New models, controllers, or major components added
     - ✅ Configuration changes that affect the application
     - ✅ Documentation updates (including this CLAUDE.md file)
     - ✅ Test suite additions or improvements

4. **When to Ask First**
   - If you're unsure whether a change is significant enough to commit, ASK THE USER
   - If changes are experimental or might need to be reverted, ASK THE USER
   - If you're about to commit a large number of files (50+), ASK THE USER if they want it split up
   - Never commit broken or failing code without explicit user approval

### What Makes a Good Commit

**Good commit examples:**
- "Add LeagueResolvable concern with intelligent league resolution"
- "Fix DraftBoardController RecordNotFound error with league auto-resolution"
- "Implement player value calculation algorithm with tests"
- "Add CSV import for player projections with error handling"

**Bad commit examples:**
- "Fix stuff" (too vague)
- "WIP" (incomplete work)
- "Updates" (doesn't describe what was updated)
- "Fix typo" (unless it's truly just a typo - bundle small fixes together)

### Commit Message Format

Follow this format for commit messages:

```
Brief summary of the change (50-70 characters max)

- Detailed explanation of WHAT changed
- WHY the change was necessary
- Any important implementation decisions
- Related issues or context

Co-Authored-By: Claude Opus 4.6 <noreply@anthropic.com>
```

### Current Git Status

**Branch:** main (3 commits ahead of origin/main)
**Recent Commits:**
1. Backend implementation (31f3399) - 130 files, 5102 insertions
2. Hotwire frontend (b0408bd) - 36 files, 943 insertions
3. LeagueResolvable concern and DraftBoard fix (e29ac54) - 12 files, 524 insertions

### Before Committing - Security Checklist

**ALWAYS verify before committing:**
- ✅ `.gitignore` properly excludes sensitive files
- ✅ No `.env` files, credentials, or API keys
- ✅ No database dumps or seed data with real user information
- ✅ No debug logs with sensitive information
- ✅ `backend/.gitignore` properly excludes Rails temp files

### When NOT to Commit

**DO NOT commit:**
- ❌ Broken or failing code (unless explicitly discussed with user)
- ❌ Commented-out code blocks (clean them up first)
- ❌ Debug statements like `console.log` or `puts` (remove them first)
- ❌ Temporary test files or experiments
- ❌ Large binary files or generated assets (unless necessary)
- ❌ Changes to `.env` files, `database.yml` credentials, or secrets

---

## Quick Reference Commands

### Start Application Locally
```bash
# Start PostgreSQL (if not running)
cd /Users/ryan.kleinberg/src/FantasyDraftKit
docker-compose up -d db

# Start Rails server with Hotwire frontend (Port 3639)
cd backend
bundle install
rails db:create
rails db:migrate
rails db:seed  # Optional: loads sample data
rails server -p 3639
```

### Access Application
- Web UI: http://localhost:3639/
- API endpoints: http://localhost:3639/api/v1/*
- Database: localhost:5434

### Useful Rails Commands
```bash
# Database operations
rails db:reset              # Drop, create, migrate, seed
rails db:migrate:status     # Check migration status

# Console
rails console               # Interactive Ruby console with app loaded

# Routes
rails routes | grep api     # List all API routes
rails routes | grep -v api  # List all web UI routes
```

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
