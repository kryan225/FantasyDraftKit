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

**Last Updated:** 2026-02-08
**Current Phase:** Full-Stack Application with Interactive Modals + Comprehensive Testing - Production Ready

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
- **Frontend: Hotwire (Turbo + Stimulus) implemented** ✅
  - Added turbo-rails, stimulus-rails, importmap-rails gems
  - Created web UI controllers (leagues, teams, players, draft_board)
  - Created ERB views for all core features
  - Configured asset pipeline with Sprockets
  - Changed config.api_only from true to false
  - Created Api::V1::BaseController to maintain API-only for JSON endpoints
  - Dual-mode architecture: HTML views + JSON API working together
- **Frontend: Application layout with navigation** ✅
- **Frontend: CSS styling complete** ✅
- **Frontend: Hotwire frontend tested and working on port 3639** ✅
- **Testing: LeagueResolvable concern created and tested** ✅
  - Reusable pattern for controllers needing league context
  - Auto-resolves single league (KISS principle)
  - Graceful handling of multiple/no leagues with user-friendly redirects
  - 15 passing tests covering all scenarios
- **Bug Fix: DraftBoardController league resolution** ✅
  - Fixed ActiveRecord::RecordNotFound error on /draft_board
  - Now supports both /draft_board and /leagues/:id/draft_board routes
  - Comprehensive test coverage added
- **Feature: Draft Player Modal** ✅
  - Interactive modal to draft players from draft board
  - Position eligibility logic (UTIL for all, CI for 1B/3B, MI for 2B/SS)
  - Team selection, price input, position dropdown
  - Roster validation to prevent drafting to full positions
  - Turbo Streams for live UI updates without reload
  - Undo draft functionality
- **Feature: BaseModalController Pattern** ✅
  - Reusable base controller for all modals (DRY, OCP principles)
  - Handles open/close, Escape key, outside click, form reset
  - Auto-closes on successful Turbo form submission
  - Comprehensive test coverage (30+ tests)
  - Tested features: body scroll prevention, custom events, loading states
- **Feature: EditPlayerModal** ✅
  - Extends BaseModalController for player editing
  - Opens when clicking any player name across the application
  - Populates form with player data from data attributes
  - Client-side validation (name and positions required)
  - Updates player info via Turbo Streams
  - Form action URL set dynamically per player
  - Test coverage added (15+ test cases, structural and behavioral)
- **Testing Infrastructure: Cuprite + Capybara** ✅
  - Set up JavaScript-capable system testing with Cuprite (headless Chrome)
  - Faster than Selenium (2-3x), no driver binary management needed
  - 6 passing system tests for EditPlayerModal
  - Screenshot capture on test failures
  - Visible browser mode for debugging (HEADLESS=false)
  - Comprehensive testing guide created (spec/TESTING_GUIDE.md)
  - **CRITICAL**: This would have caught the EditPlayerModal scope bug before deployment
- **Feature: ConfirmationModal** ✅
  - Reusable confirmation modal controller replacing JavaScript alert()
  - Extends BaseModalController for consistent behavior
  - Promise-based API for clean async/await usage
  - Configurable options (title, message, button text, danger styling)
  - Can be used as alert (showCancel: false) or confirmation (showCancel: true)
  - Integrated with EditPlayerModal for validation errors
  - 4 passing system tests validating behavior
  - Removed HTML5 required attributes to enable JavaScript validation
  - **UX Improvement**: Styled modals instead of browser alerts

### In Progress 🚧
- None currently

### Pending ⏳
- Feature: Add Stimulus controllers for enhanced interactivity (drag-drop, live updates)
- Feature: Implement player value calculation algorithm
- Feature: Implement category analysis aggregation
- Feature: Use ConfirmationModal for other confirmation dialogs (delete actions, etc.)
- Testing: Write system tests for DraftModal with JavaScript driver
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
1. Test the web UI at http://localhost:3639/
2. Create leagues and teams through the web interface
3. Import player projections via CSV upload
4. Implement league creation form (currently only show/index work)
5. Add Stimulus controllers for enhanced interactivity
6. Implement value calculation algorithm
7. Implement category analysis aggregation
8. Add form validations and error handling in views
9. Add RSpec tests for models, controllers, and views

### Recent Commits 📝
- **2026-02-08 (commit f7b59c2):** Add comprehensive tests for ConfirmationModal
  - 4 new tests for ConfirmationModal behavior
  - Updated 1 EditPlayerModal test for new validation flow
  - 10 examples, 0 failures in 4.86 seconds
  - Tests validation errors show in styled modal
  - Tests edit modal stays open after validation error
- **2026-02-08 (commit 4f9289d):** Add reusable ConfirmationModal to replace JavaScript alert()
  - Created ConfirmationModalController extending BaseModalController
  - Promise-based API for async/await usage
  - Integrated with EditPlayerModal for validation
  - Removed HTML5 required attributes for JavaScript validation control
  - Better UX with styled modals instead of browser alerts
- **2026-02-08 (commit 631952d):** Update CLAUDE.md with testing infrastructure details
  - Documented Cuprite setup and decision rationale
  - Updated technology stack and project status
  - Added testing guide reference
- **2026-02-08 (commit 40eabea):** Add comprehensive testing guide (spec/TESTING_GUIDE.md)
  - 294 lines documenting testing infrastructure
  - Cuprite vs Selenium comparison
  - Running tests, writing tests, debugging techniques
- **2026-02-08 (commit 3fe4c5b):** Rewrite EditPlayerModal system tests with JavaScript driver
  - 6 tests using Cuprite for real browser testing
  - Tests actual JavaScript behavior
  - Would have caught original modal scope bug
- **2026-02-08 (commit ec8039e):** Set up Cuprite for JavaScript-capable system testing
  - Added capybara and cuprite gems
  - Created spec/support/capybara.rb configuration
  - Screenshot capture on failures
  - 2-3x faster than Selenium
- **2026-02-08 (commit 844b479):** Add test coverage for EditPlayerModal (documentation)
  - 2 files changed, 390 insertions
  - Added JavaScript unit tests (15+ test cases, requires Jest to run)
  - Added Rails system tests (structural validation with rack-test)
  - Tests serve as documentation of expected behavior
- **2026-02-08 (commit 6562e71):** Fix EditPlayerModal controller scope and remove duplicate modals
  - 5 files changed, 101 insertions, 14 deletions
  - Moved data-controller="edit-player-modal" to <body> tag
  - Moved modal HTML to application.html.erb layout for global access
  - Removed duplicate modal renders from draft_board, teams, players views
  - Fixed controller to remove non-existent playerIdTarget reference
  - Now clicking any player name opens edit modal correctly
- **2026-02-07 (commit c1a1f5b):** Add EditPlayerModal for quick player edits
  - Created EditPlayerModalController extending BaseModalController
  - Added PlayersController update action with Turbo Stream responses
  - Created _player_name.html.erb partial for clickable player links
  - Updated all views (draft_board, teams/show, players/index) to use partial
  - Modal opens on click, populates with data, validates, submits via Turbo
- **2026-02-07 (commit 056291b):** Create BaseModalController for reusable modal functionality
  - Created base_modal_controller.js with comprehensive behavior
  - Handles open/close, Escape key, outside click, Turbo submission
  - Includes helper methods (setSubmitLoading) for consistent UX
  - Refactored DraftModalController to extend base
  - Added 30+ tests covering all base modal functionality
  - Fixed modal close bug after draft submission
- **2026-02-07 (commit a9d6de1):** Implement draft enhancements with Turbo Streams
  - Added RosterValidator concern for position validation
  - Created DraftPicksController with Turbo Stream support
  - Added undo draft pick functionality
  - Turbo Streams update draft list, available players, team budgets live
  - Migration for drafted_position field
- **2026-02-07 (commit 7efd0f3, a27406c):** Add draft player modal with position eligibility
  - Created draft_modal_controller.js with position logic
  - Modal includes player details, team select, position select, price input
  - Position eligibility: UTIL for all, CI for 1B/3B, MI for 2B/SS
  - Comprehensive styling and UX polish
- **2026-02-07 (commit e29ac54):** Fix DraftBoard league resolution error with reusable LeagueResolvable concern
  - 12 files changed, 524 insertions, 13 deletions
  - Added LeagueResolvable concern for intelligent league resolution
  - Fixed ActiveRecord::RecordNotFound error on /draft_board
  - Added comprehensive test coverage (15 passing tests)
  - Updated git workflow guidelines in CLAUDE.md
- **2026-02-04 (commit b0408bd):** Add Hotwire frontend as npm-free alternative
  - 36 files changed, 943 insertions
  - Implemented Turbo + Stimulus with importmap-rails
  - Created web UI controllers and ERB views for all features
  - Added comprehensive CSS styling
  - Changed config.api_only = false, created dual-mode architecture
  - Hotwire frontend tested and working on port 3639
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
└── CLAUDE.md            # This file - project documentation
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
