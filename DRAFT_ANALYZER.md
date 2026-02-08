# Draft Analyzer - Feature Documentation

**Purpose**: Real-time analytics and insights to inform draft strategy during live auction drafts.

**Last Updated**: 2026-02-08

---

## Philosophy

- **Primary Use Case**: During-draft decision support (real-time insights)
- **MVP Approach**: Start small, add features incrementally
- **Performance**: Heavy calculations may be expensive - optimize as needed

---

## Current Features

### ✅ Roster Fill Rate by Position
**Status**: Implemented

**What it shows**:
- Available roster spots remaining for each position across the entire league
- Total slots vs. filled slots for each position type
- Percentage filled
- **Teams Can Draft**: Clickable count showing which teams can still draft each position

**Position Eligibility Rules**:
- **UTIL**: Can be filled by any batter position (C, 1B, 2B, 3B, SS, OF)
- **MI**: Can be filled by 2B or SS
- **CI**: Can be filled by 1B or 3B
- **Standard positions**: Only their specific position (C, 1B, 2B, 3B, SS, OF, SP, RP, BENCH)

**Implementation Notes**:
- Aggregates roster_config across all teams
- Counts draft picks by drafted_position
- Shows league-wide scarcity

**Teams Can Draft Logic (Bidirectional One-Level Lookahead)**:
- A team can draft a position if:
  1. They have an empty slot at that position, OR
  2. They have a player in a flex position (UTIL/MI/CI) who could be moved TO this position, OR
  3. They have a player at this position who could be moved OUT to ANY other position with available space
- Examples:
  - Team has 2/2 C filled, but one C is sitting at UTIL → can draft C (direction 2)
  - Team has 1/1 1B filled, but could move the 1B to empty CI or UTIL → can draft 1B (direction 3)
  - Team has 1/1 UTIL filled with OF player, but OF has 2 open slots → can draft UTIL (direction 3)
- Direction 3 checks ALL positions (not just flex), enabling complex roster flexibility
- Clickable count opens modal showing list of eligible teams
- Performance: O(teams × positions² × draft_picks) - still fast for typical league size

---

## Planned Features (Priority Order)

### 🔲 Top Values Remaining (by position)
**Priority**: High
**Description**: Best available players by position, sorted by calculated_value
- Helps identify value opportunities
- Should filter by position eligibility

### 🔲 Recent Picks Analysis
**Priority**: High
**Description**: Last 10-15 picks showing price vs. calculated value
- Shows market temperature (hot/cold)
- Highlights bargains and overpays
- Table format: Pick #, Player, Position, Price, Value, Diff

### 🔲 Spending by Position
**Priority**: Medium
**Description**: Total $ spent per position across league
- Simple table or bar chart
- Average price per position
- Shows where money is concentrating

### 🔲 Team Budget Comparison
**Priority**: Medium
**Description**: Enhanced version of existing team budgets
- Sort by various metrics (budget remaining, roster filled %, etc.)
- Aggressive vs. conservative spenders
- Stars & scrubs detection (spending variance)

### 🔲 Position Run Detector
**Priority**: Medium
**Description**: Identifies when position runs are happening
- "5 catchers drafted in last 8 picks"
- Real-time alerts during draft

### 🔲 Price Trends Over Time
**Priority**: Low (expensive calculation)
**Description**: Chart showing price inflation/deflation
- Average price per pick over time
- Requires charting library (Chart.js?)

### 🔲 Projected vs. Actual Prices
**Priority**: Low (expensive calculation)
**Description**: Scatter plot analysis post-draft
- Shows market efficiency
- Identifies systematic over/undervaluation

---

## Technical Considerations

### Performance
- Start with simple queries and aggregations
- Consider caching for expensive calculations
- Monitor page load times as features are added
- May need background jobs for complex analytics

### Data Requirements
- `draft_picks`: All current picks with prices and positions
- `players`: Calculated values and position eligibility
- `teams`: Roster configurations (JSONB)
- `league`: Roster template (roster_config)

### UI/UX
- Keep it clean and scannable during live draft
- Most important metrics at top
- Consider making sections collapsible (use existing collapsible controller)
- Mobile-friendly for draft day

---

## Future Ideas (Backlog)

- Player availability alerts (notify when key targets become affordable)
- Keeper analysis (value of keeper picks vs. auction)
- Category strength prediction (project team stats based on roster)
- Opponent strategy profiles (spending patterns, position priorities)
- Draft grade calculator (how well did teams optimize?)
- Export draft recap as PDF/CSV

---

## Implementation Log

**2026-02-08**:
- Created DRAFT_ANALYZER.md documentation file
- Implemented roster fill rate by position (MVP feature)
- Created draft_analyzer route and controller
- Created draft_analyzer view with collapsible section
- Added "Teams Can Draft" metric with one-level lookahead logic
  - Checks direct slot availability AND flex position moveability
  - Clickable modal shows list of teams who can draft each position
  - Extends BaseModalController for consistent modal behavior
  - Added helper methods for position eligibility checking
