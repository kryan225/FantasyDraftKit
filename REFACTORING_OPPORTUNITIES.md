# Refactoring Opportunities

This document tracks identified code duplication and refactoring opportunities that can be addressed when working in related areas of the codebase.

**Last Updated:** 2026-02-07

---

## Philosophy: Refactor When Needed

Following **YAGNI (You Ain't Gonna Need It)** principle:
- ✅ Address high-impact issues that affect maintainability now
- 📋 Document lower-impact issues for future work
- 🎯 Refactor when working in the relevant code area
- ⏰ Don't over-engineer or prematurely optimize

---

## ✅ Completed Refactorings

### 1. Position Eligibility Logic (2026-02-07)
**Status:** ✅ Complete
**Impact:** Eliminated 33 lines, created single source of truth
**Files:** Created `PositionEligibility` concern and `position_eligibility.js` utility
**Commit:** `3e99feb` - Refactor position eligibility logic following DRY and testing pyramid

### 2. Player Stats Display (2026-02-07)
**Status:** ✅ Complete
**Impact:** Eliminated 33 lines across 3 views
**Files:** Created `app/views/players/_stats_columns.html.erb`
**Commit:** `cd8fa95` - Refactor player stats display - eliminate 33 lines of duplication

### 3. Turbo Stream Response Duplication (2026-02-07)
**Status:** ✅ Complete
**Impact:** Eliminated 20 lines, reduced file sizes by 50%+
**Files:** Created `app/views/draft_board/_update_board.turbo_stream.erb`
**Commit:** `e4ec7f6` - Refactor Turbo Stream responses - eliminate 20 lines of duplication

---

## 📋 Remaining Opportunities (Prioritized)

### OPPORTUNITY #1: Roster Calculations in Views

**Impact:** 8/10 | **Lines Saved:** 12 | **Effort:** Low | **Priority:** HIGH

**Issue:**
Max bid calculation business logic is repeated in views instead of residing in the Team model:

**Location 1:** `app/views/draft_board/_team_budgets.html.erb` (lines 8-11)
```erb
<% remaining_spots = total_slots - filled_slots %>
<% max_bid = remaining_spots > 0 ? team.budget_remaining - (remaining_spots - 1) : team.budget_remaining %>
```

**Location 2:** `app/views/teams/show.html.erb` (lines 9-11)
```erb
remaining_spots = total_roster_spots - @team.draft_picks.count
max_bid = remaining_spots > 0 ? @team.budget_remaining - (remaining_spots - 1) : @team.budget_remaining
```

**Recommended Solution:**
Add to `app/models/team.rb`:
```ruby
# Calculate maximum bid amount team can make while reserving $1 for remaining roster slots
#
# @return [Integer] Maximum amount team can bid on a player
def max_bid
  total_slots = league.roster_config&.values&.sum || 0
  remaining_spots = total_slots - draft_picks.count
  remaining_spots > 0 ? budget_remaining - (remaining_spots - 1) : budget_remaining
end
```

Then in views: `<%= team.max_bid %>`

**Benefits:**
- Moves business logic from view to model (Rails best practice)
- Testable with unit tests
- Single source of truth for calculation
- Easier to modify algorithm in future
- Follows "fat models, skinny views" convention

**When to Refactor:**
- When working on team budget display
- When adding team budget tests
- When modifying max bid calculation logic

**Principles Applied:**
- Single Responsibility (Team owns its budget calculations)
- Separation of Concerns (business logic in model, not view)
- Testability (can unit test the method)

---

### OPPORTUNITY #2: Error Partial Duplication

**Impact:** 8/10 | **Lines Saved:** 8 | **Effort:** Low | **Priority:** HIGH

**Issue:**
Two error partials have identical structure with only the title differing:

**Location 1:** `app/views/draft_picks/_error.html.erb` (8 lines)
```erb
<div class="flash flash-alert">
  <strong>Draft Error:</strong>
  <ul style="margin: 0.5rem 0 0 1.5rem;">
    <% errors.each do |error| %>
      <li><%= error %></li>
    <% end %>
  </ul>
</div>
```

**Location 2:** `app/views/players/_error.html.erb` (8 lines)
- Identical structure, different title: "Update Error:"

**Also Referenced In:**
- `app/controllers/draft_picks_controller.rb:77` - references `"shared/error"` but file doesn't exist

**Recommended Solution:**
Create `app/views/shared/_error_alert.html.erb`:
```erb
<%# Generic error display for flash messages
    Params:
    - errors: Array of error messages
    - title: String (optional, default: "Error:")
%>
<div class="flash flash-alert">
  <strong><%= local_assigns.fetch(:title, "Error:") %></strong>
  <ul style="margin: 0.5rem 0 0 1.5rem;">
    <% errors.each do |error| %>
      <li><%= error %></li>
    <% end %>
  </ul>
</div>
```

Usage: `<%= render "shared/error_alert", errors: @errors, title: "Draft Error:" %>`

**Benefits:**
- Generic error display for entire application
- Consistent error formatting
- Easy to add styling or behavior changes
- Follows DRY principle

**When to Refactor:**
- When working on error handling
- When adding new forms that need error display
- When styling error messages

**Principles Applied:**
- DRY (Don't Repeat Yourself)
- Interface Segregation (generic component with optional title)
- Separation of Concerns (error presentation in one place)

---

### OPPORTUNITY #3: Position Groups Definition

**Impact:** 7.5/10 | **Lines Saved:** 16 | **Effort:** Medium | **Priority:** HIGH

**Issue:**
Position groups array is hardcoded in multiple locations:

**Location 1:** `app/controllers/draft_picks_controller.rb` (lines 60-65)
```ruby
@position_groups = [
  { name: "Batters", positions: ["C", "1B", "2B", "3B", "SS", "MI", "CI", "OF"] },
  { name: "Utility", positions: ["UTIL"] },
  { name: "Pitchers", positions: ["SP", "RP"] },
  { name: "Bench", positions: ["BENCH"] }
]
```

**Location 2:** `app/views/teams/show.html.erb` (lines 44-49)
- Identical array definition in ERB view

**Recommended Solution:**
Create `app/models/concerns/position_groupable.rb`:
```ruby
# frozen_string_literal: true

# PositionGroupable - Provides position grouping constants
#
# Groups roster positions into logical categories for display purposes
module PositionGroupable
  extend ActiveSupport::Concern

  # Position groups for roster display
  # Used to organize roster tables into sections (Batters, Pitchers, etc.)
  POSITION_GROUPS = [
    { name: "Batters", positions: ["C", "1B", "2B", "3B", "SS", "MI", "CI", "OF"] },
    { name: "Utility", positions: ["UTIL"] },
    { name: "Pitchers", positions: ["SP", "RP"] },
    { name: "Bench", positions: ["BENCH"] }
  ].freeze

  # Returns position groups for this object's context
  #
  # @return [Array<Hash>] Position groups with names and positions
  def position_groups
    self.class::POSITION_GROUPS
  end
end
```

Include in League model:
```ruby
class League < ApplicationRecord
  include PositionGroupable
  # ...
end
```

Usage in controllers: `@position_groups = @league.position_groups`
Usage in views: `<% League::POSITION_GROUPS.each do |group| %>`

**Benefits:**
- Single source of truth for position groups
- Testable constant
- Available to all models, controllers, and views
- Easy to modify groupings in one place

**When to Refactor:**
- When adding new position groups
- When working on roster display logic
- When creating position group tests

**Principles Applied:**
- DRY (Don't Repeat Yourself)
- Single Source of Truth
- Separation of Concerns (domain logic in model layer)

---

### OPPORTUNITY #4: Player Info Display Pattern

**Impact:** 7/10 | **Lines Saved:** 8 | **Effort:** Low | **Priority:** MEDIUM

**Issue:**
Player name + positions + team display pattern repeats in multiple views:

**Pattern in 3 locations:**
```erb
<%= render partial: "players/player_name", locals: { player: pick.player } %>
<br>
<small class="text-muted"><%= pick.player.positions %> - <%= pick.player.mlb_team %></small>
```

**Locations:**
- `app/views/draft_board/_draft_picks_table.html.erb`
- `app/views/teams/show.html.erb` (line 111-113)
- `app/views/draft_picks/update.turbo_stream.erb` (line 64-66)

**Recommended Solution:**
Create `app/views/players/_player_with_details.html.erb`:
```erb
<%# Player name with position and team details
    Displays player name (linked) with positions and MLB team below

    Params:
    - player: Player object
%>
<%= render partial: "players/player_name", locals: { player: player } %>
<br>
<small class="text-muted"><%= player.positions %> - <%= player.mlb_team %></small>
```

Usage: `<%= render "players/player_with_details", player: pick.player %>`

**Benefits:**
- Consistent player info display
- Single place to change formatting
- Can easily add additional info (age, status, etc.)
- Follows component-based design

**When to Refactor:**
- When working on player display
- When adding new player information
- When changing player info formatting

**Principles Applied:**
- DRY (Don't Repeat Yourself)
- Single Responsibility (player info display in one component)
- Reusable Components

---

## 🔧 How to Use This Document

### When Working on Code:

1. **Check if area has opportunities** - Search this document for relevant files
2. **Assess if refactoring makes sense** - Is it worth doing now?
3. **Follow the recommended solution** - Copy/paste/adapt the provided code
4. **Update this document** - Move item to "Completed Refactorings" section
5. **Commit with reference** - Link to this document in commit message

### When to Refactor:

✅ **DO refactor if:**
- You're already modifying the code in that area
- You're adding tests and can test the refactored code
- You're adding a feature that would benefit from the refactoring
- The duplication is causing immediate bugs or confusion

❌ **DON'T refactor if:**
- You're just passing through and not working on related features
- You don't have time to test the changes properly
- The code works fine and isn't causing problems
- It would be a "drive-by" change without clear benefit

### Refactoring Checklist:

- [ ] Read the opportunity description and understand the issue
- [ ] Review the recommended solution and adapt to current code
- [ ] Write or update tests for the refactored code
- [ ] Run existing tests to ensure no regressions
- [ ] Update any documentation affected by changes
- [ ] Commit with clear message explaining the refactoring
- [ ] Update this document (move to "Completed" section)

---

## 📚 Related Documentation

- **CLAUDE.md** - Project documentation and testing philosophy
- **DRAFT_ANALYZER.md** - Draft analyzer feature roadmap
- **Testing Pyramid** - See CLAUDE.md "Testing Strategy" section

---

## 💡 Future Opportunities to Discover

As the codebase evolves, new refactoring opportunities may emerge. When you notice duplication or code smells:

1. **Document it here** - Add to this file with impact assessment
2. **Prioritize it** - Rate impact, effort, and when to address
3. **Provide solution** - Include recommended approach with code examples
4. **Link it** - Reference related files and line numbers

**Common patterns to watch for:**
- Repeated calculations or business logic
- Duplicated view patterns (HTML/ERB)
- Similar controller actions
- Copied helper methods
- Hardcoded constants in multiple places

---

## 🎯 Refactoring Principles

All refactorings should follow these principles from CLAUDE.md:

1. **SOLID Principles**
   - Single Responsibility
   - Open/Closed
   - Liskov Substitution
   - Interface Segregation
   - Dependency Inversion

2. **DRY, KISS, YAGNI**
   - Don't Repeat Yourself
   - Keep It Simple, Stupid
   - You Ain't Gonna Need It

3. **Testing Pyramid**
   - Maintain 60/30/10 ratio (Unit/Integration/E2E)
   - Add unit tests for extracted methods
   - Keep tests fast and focused

4. **Rails Best Practices**
   - Fat models, skinny controllers
   - Business logic in models
   - Presentation logic in helpers/partials
   - RESTful design patterns
