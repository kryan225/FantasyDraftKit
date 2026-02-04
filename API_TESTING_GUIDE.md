# Fantasy Baseball Draft Kit - API Testing Guide

## 🚀 Quick Start

The backend API is fully functional and populated with test data. You can test all endpoints while waiting for frontend dependencies to install.

### Current Services Running

```
✅ PostgreSQL: localhost:5434
✅ Rails API:   http://localhost:3639
⏳ Frontend:    (pending npm install)
```

---

## 📊 Test Data Summary

Run `rails db:seed` has populated:

- **1 League**: "2026 Fantasy Baseball League" (12 teams, $260 budget)
- **35 Players**: Mix of elite, mid-tier, and value players with projections
- **12 Teams**: Bombers, Sluggers, Dingers, Aces, Mavericks, Thunder, Storm, Titans, Warriors, Legends, Champions, Dynasty
- **6 Draft Picks**: First 6 picks simulated with budget deductions
- **6 Keeper Records**: Historical keeper data from 2025

---

## 🧪 API Endpoint Tests

### Leagues

**Get all leagues:**
```bash
curl http://localhost:3639/api/v1/leagues | jq '.'
```

**Get league details with teams:**
```bash
curl http://localhost:3639/api/v1/leagues/3 | jq '.'
```

**Create a new league:**
```bash
curl -X POST http://localhost:3639/api/v1/leagues \
  -H "Content-Type: application/json" \
  -d '{
    "league": {
      "name": "My Custom League",
      "team_count": 10,
      "auction_budget": 300,
      "keeper_limit": 5
    }
  }' | jq '.'
```

**Update a league:**
```bash
curl -X PATCH http://localhost:3639/api/v1/leagues/3 \
  -H "Content-Type: application/json" \
  -d '{
    "league": {
      "name": "Updated League Name"
    }
  }' | jq '.'
```

---

### Players

**Get all players:**
```bash
curl http://localhost:3639/api/v1/players | jq '.'
```

**Get top 5 players by value:**
```bash
curl 'http://localhost:3639/api/v1/players?order_by=calculated_value&order_direction=desc' \
  | jq '.[0:5] | .[] | {name, value: .calculated_value, positions}'
```

**Filter by position:**
```bash
curl 'http://localhost:3639/api/v1/players?position=SP' | jq 'length'
```

**Search by name:**
```bash
curl 'http://localhost:3639/api/v1/players?search=Judge' | jq '.[] | .name'
```

**Get only available (undrafted) players:**
```bash
# Note: URL encode the query parameter
curl 'http://localhost:3639/api/v1/players' \
  --data-urlencode 'is_drafted=false' \
  | jq 'length'
```

---

### Teams

**Get all teams in a league:**
```bash
curl http://localhost:3639/api/v1/leagues/3/teams | jq '.'
```

**Get team details with roster:**
```bash
curl http://localhost:3639/api/v1/teams/13 | jq '.'
```

**Create a new team:**
```bash
curl -X POST http://localhost:3639/api/v1/leagues/3/teams \
  -H "Content-Type: application/json" \
  -d '{
    "team": {
      "name": "New Team Name"
    }
  }' | jq '.'
```

**Get team category analysis:**
```bash
curl http://localhost:3639/api/v1/teams/13/category_analysis | jq '.'
```

---

### Draft Picks

**Get all draft picks for a league:**
```bash
curl http://localhost:3639/api/v1/leagues/3/draft_picks | jq '.'
```

**Record a new draft pick:**
```bash
curl -X POST http://localhost:3639/api/v1/leagues/3/draft_picks \
  -H "Content-Type: application/json" \
  -d '{
    "draft_pick": {
      "team_id": 13,
      "player_id": 70,
      "price": 32,
      "is_keeper": false
    }
  }' | jq '.'
```

**Undo a draft pick (delete):**
```bash
curl -X DELETE http://localhost:3639/api/v1/draft_picks/18
```

---

### Keeper History

**Get keeper history for a league:**
```bash
curl http://localhost:3639/api/v1/leagues/3/keeper_history | jq '.'
```

**Check keeper eligibility:**
```bash
curl 'http://localhost:3639/api/v1/leagues/3/check_keeper_eligibility?player_id=51&team_id=13' \
  | jq '.'
```

---

## 🔍 Interesting Queries to Try

### Show teams sorted by remaining budget:
```bash
curl http://localhost:3639/api/v1/leagues/3/teams \
  | jq 'sort_by(.budget_remaining) | .[] | {name, budget: .budget_remaining}'
```

### Show only drafted players:
```bash
curl http://localhost:3639/api/v1/players \
  | jq '[.[] | select(.is_drafted == true)] | .[] | {name, positions, value: .calculated_value}'
```

### Show elite closers (saves > 30):
```bash
curl http://localhost:3639/api/v1/players \
  | jq '[.[] | select(.projections.saves > 30)] | .[] | {name, saves: .projections.saves, value: .calculated_value}'
```

### Show power/speed combo (20+ HR, 20+ SB):
```bash
curl http://localhost:3639/api/v1/players \
  | jq '[.[] | select(.projections.home_runs > 20 and .projections.stolen_bases > 20)] | .[] | {name, hr: .projections.home_runs, sb: .projections.stolen_bases}'
```

### Team spending analysis:
```bash
curl http://localhost:3639/api/v1/leagues/3/teams \
  | jq '.[] | {name, spent: (260 - .budget_remaining), remaining: .budget_remaining}'
```

---

## 📝 Sample CSV Import

### Player Import Format

Create a file `players.csv`:
```csv
name,positions,Team,R,HR,RBI,SB,AVG,W,SV,K,ERA,WHIP,Value
Juan Soto,OF,NYY,100,40,110,10,0.285,,,,,28
Bryce Harper,OF,PHI,95,35,100,12,0.280,,,,,26
Framber Valdez,SP,HOU,,,,,14,0,185,3.40,1.15,22
```

**Import players:**
```bash
curl -X POST http://localhost:3639/api/v1/players/import \
  -F "file=@players.csv"
```

### Keeper Import Format

Create a file `keepers.csv`:
```csv
team,player,year,price
Bombers,Ronald Acuña Jr.,2024,35
Sluggers,Shohei Ohtani,2024,38
```

**Import keepers:**
```bash
curl -X POST http://localhost:3639/api/v1/leagues/3/import_keepers \
  -F "file=@keepers.csv"
```

---

## 🎯 Business Logic Demonstrations

### Automatic Budget Management

When you create a draft pick, the API automatically:
1. Deducts the price from the team's budget
2. Marks the player as drafted
3. Assigns a pick number

```bash
# Before: Check team budget
curl http://localhost:3639/api/v1/teams/13 | jq '.budget_remaining'
# Returns: 215

# Draft a player for $25
curl -X POST http://localhost:3639/api/v1/leagues/3/draft_picks \
  -H "Content-Type: application/json" \
  -d '{
    "draft_pick": {
      "team_id": 13,
      "player_id": 60,
      "price": 25
    }
  }'

# After: Budget automatically updated
curl http://localhost:3639/api/v1/teams/13 | jq '.budget_remaining'
# Returns: 190
```

### Undo Draft Pick (Budget Refund)

Deleting a draft pick automatically:
1. Refunds the price to the team
2. Marks the player as available again

```bash
curl -X DELETE http://localhost:3639/api/v1/draft_picks/18

# Team budget is refunded automatically
```

### Keeper Eligibility Tracking

```bash
# Check if a player is eligible to be kept
curl 'http://localhost:3639/api/v1/leagues/3/check_keeper_eligibility?player_id=51&team_id=13' \
  | jq '{eligible, years_kept, limit: .keeper_limit, message}'
```

---

## 🐛 Troubleshooting

### Port Already in Use
```bash
# Check what's using port 3639
lsof -i :3639

# Kill the process if needed
kill -9 <PID>
```

### Database Connection Issues
```bash
# Verify PostgreSQL is running
lsof -i :5434

# Restart PostgreSQL container
cd /Users/ryan.kleinberg/src/FantasyDraftKit
docker-compose restart db
```

### Reset Database
```bash
# Drop, recreate, migrate, and seed
rails db:reset
```

---

## 🔗 Next Steps

Once frontend dependencies install successfully:

1. Start frontend: `npm run dev -- --port 1147`
2. Access UI: http://localhost:1147
3. Backend will be ready at: http://localhost:3639

The frontend is already configured to connect to port 3639, so integration should be seamless.

---

## 📚 API Documentation

All endpoints follow RESTful conventions:

- **GET**: Retrieve resources
- **POST**: Create new resources
- **PATCH/PUT**: Update existing resources
- **DELETE**: Remove resources

**Response Codes:**
- `200 OK`: Successful GET/PATCH/DELETE
- `201 Created`: Successful POST
- `204 No Content`: Successful DELETE
- `404 Not Found`: Resource doesn't exist
- `422 Unprocessable Entity`: Validation errors
- `500 Internal Server Error`: Server error

**Error Response Format:**
```json
{
  "error": "Validation failed: Name can't be blank",
  "errors": ["Name can't be blank", "Team count must be greater than 0"]
}
```
