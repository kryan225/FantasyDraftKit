# Fantasy Baseball Draft Kit - Seed Data
# This creates sample data for testing the application
# Run with: rails db:seed

puts "🧹 Cleaning existing data..."
DraftPick.destroy_all
KeeperHistory.destroy_all
Player.destroy_all
Team.destroy_all
League.destroy_all

puts "🏆 Creating test league..."
league = League.create!(
  name: "2026 Fantasy Baseball League",
  team_count: 12,
  auction_budget: 260,
  keeper_limit: 3,
  roster_config: {
    "C" => 1,
    "1B" => 1,
    "2B" => 1,
    "3B" => 1,
    "SS" => 1,
    "OF" => 3,
    "UTIL" => 2,
    "SP" => 5,
    "RP" => 3,
    "BENCH" => 5
  }
)

puts "👥 Creating teams..."
team_names = [
  "Bombers",
  "Sluggers",
  "Dingers",
  "Aces",
  "Mavericks",
  "Thunder",
  "Storm",
  "Titans",
  "Warriors",
  "Legends",
  "Champions",
  "Dynasty"
]

teams = team_names.map do |name|
  league.teams.create!(
    name: name,
    budget_remaining: 260
  )
end

puts "⚾ Creating sample players..."

# Elite Hitters
players_data = [
  # Top Hitters
  { name: "Ronald Acuña Jr.", positions: "OF", mlb_team: "ATL",
    projections: { "runs" => 120, "home_runs" => 40, "rbi" => 100, "stolen_bases" => 70, "batting_average" => 0.285 },
    calculated_value: 45 },
  { name: "Shohei Ohtani", positions: "OF,DH", mlb_team: "LAD",
    projections: { "runs" => 100, "home_runs" => 45, "rbi" => 110, "stolen_bases" => 25, "batting_average" => 0.290 },
    calculated_value: 42 },
  { name: "Mookie Betts", positions: "OF", mlb_team: "LAD",
    projections: { "runs" => 110, "home_runs" => 35, "rbi" => 95, "stolen_bases" => 15, "batting_average" => 0.295 },
    calculated_value: 38 },
  { name: "Aaron Judge", positions: "OF", mlb_team: "NYY",
    projections: { "runs" => 110, "home_runs" => 50, "rbi" => 120, "stolen_bases" => 5, "batting_average" => 0.275 },
    calculated_value: 40 },
  { name: "Bobby Witt Jr.", positions: "SS", mlb_team: "KC",
    projections: { "runs" => 115, "home_runs" => 30, "rbi" => 95, "stolen_bases" => 45, "batting_average" => 0.280 },
    calculated_value: 38 },

  # Mid-tier Hitters
  { name: "Pete Alonso", positions: "1B", mlb_team: "NYM",
    projections: { "runs" => 85, "home_runs" => 40, "rbi" => 115, "stolen_bases" => 0, "batting_average" => 0.250 },
    calculated_value: 28 },
  { name: "Jose Altuve", positions: "2B", mlb_team: "HOU",
    projections: { "runs" => 90, "home_runs" => 20, "rbi" => 70, "stolen_bases" => 15, "batting_average" => 0.300 },
    calculated_value: 25 },
  { name: "Vladimir Guerrero Jr.", positions: "1B", mlb_team: "TOR",
    projections: { "runs" => 95, "home_runs" => 35, "rbi" => 105, "stolen_bases" => 2, "batting_average" => 0.285 },
    calculated_value: 32 },
  { name: "Manny Machado", positions: "3B", mlb_team: "SD",
    projections: { "runs" => 85, "home_runs" => 28, "rbi" => 90, "stolen_bases" => 8, "batting_average" => 0.275 },
    calculated_value: 26 },
  { name: "Kyle Tucker", positions: "OF", mlb_team: "HOU",
    projections: { "runs" => 95, "home_runs" => 30, "rbi" => 100, "stolen_bases" => 20, "batting_average" => 0.285 },
    calculated_value: 30 },

  # Value Hitters
  { name: "J.T. Realmuto", positions: "C", mlb_team: "PHI",
    projections: { "runs" => 75, "home_runs" => 22, "rbi" => 80, "stolen_bases" => 10, "batting_average" => 0.270 },
    calculated_value: 22 },
  { name: "Bo Bichette", positions: "SS", mlb_team: "TOR",
    projections: { "runs" => 85, "home_runs" => 25, "rbi" => 85, "stolen_bases" => 12, "batting_average" => 0.285 },
    calculated_value: 24 },
  { name: "Corey Seager", positions: "SS", mlb_team: "TEX",
    projections: { "runs" => 85, "home_runs" => 30, "rbi" => 95, "stolen_bases" => 3, "batting_average" => 0.280 },
    calculated_value: 26 },
  { name: "Matt Olson", positions: "1B", mlb_team: "ATL",
    projections: { "runs" => 90, "home_runs" => 38, "rbi" => 110, "stolen_bases" => 0, "batting_average" => 0.260 },
    calculated_value: 28 },
  { name: "Rafael Devers", positions: "3B", mlb_team: "BOS",
    projections: { "runs" => 85, "home_runs" => 32, "rbi" => 100, "stolen_bases" => 3, "batting_average" => 0.275 },
    calculated_value: 27 },

  # Elite Pitchers
  { name: "Gerrit Cole", positions: "SP", mlb_team: "NYY",
    projections: { "wins" => 15, "saves" => 0, "strikeouts" => 230, "era" => 3.10, "whip" => 1.05 },
    calculated_value: 32 },
  { name: "Spencer Strider", positions: "SP", mlb_team: "ATL",
    projections: { "wins" => 18, "saves" => 0, "strikeouts" => 260, "era" => 2.85, "whip" => 0.98 },
    calculated_value: 35 },
  { name: "Corbin Burnes", positions: "SP", mlb_team: "BAL",
    projections: { "wins" => 16, "saves" => 0, "strikeouts" => 220, "era" => 3.00, "whip" => 1.02 },
    calculated_value: 30 },
  { name: "Tarik Skubal", positions: "SP", mlb_team: "DET",
    projections: { "wins" => 14, "saves" => 0, "strikeouts" => 200, "era" => 3.20, "whip" => 1.10 },
    calculated_value: 26 },
  { name: "Zack Wheeler", positions: "SP", mlb_team: "PHI",
    projections: { "wins" => 14, "saves" => 0, "strikeouts" => 190, "era" => 3.25, "whip" => 1.08 },
    calculated_value: 24 },

  # Relief Pitchers / Closers
  { name: "Emmanuel Clase", positions: "RP", mlb_team: "CLE",
    projections: { "wins" => 5, "saves" => 40, "strikeouts" => 75, "era" => 2.50, "whip" => 1.00 },
    calculated_value: 20 },
  { name: "Félix Bautista", positions: "RP", mlb_team: "BAL",
    projections: { "wins" => 4, "saves" => 35, "strikeouts" => 80, "era" => 2.80, "whip" => 1.05 },
    calculated_value: 18 },
  { name: "Ryan Helsley", positions: "RP", mlb_team: "STL",
    projections: { "wins" => 5, "saves" => 38, "strikeouts" => 85, "era" => 2.65, "whip" => 1.03 },
    calculated_value: 19 },

  # Mid-tier Pitchers
  { name: "Blake Snell", positions: "SP", mlb_team: "SF",
    projections: { "wins" => 13, "saves" => 0, "strikeouts" => 200, "era" => 3.30, "whip" => 1.15 },
    calculated_value: 22 },
  { name: "Dylan Cease", positions: "SP", mlb_team: "SD",
    projections: { "wins" => 12, "saves" => 0, "strikeouts" => 210, "era" => 3.40, "whip" => 1.12 },
    calculated_value: 21 },
  { name: "Logan Webb", positions: "SP", mlb_team: "SF",
    projections: { "wins" => 13, "saves" => 0, "strikeouts" => 175, "era" => 3.35, "whip" => 1.10 },
    calculated_value: 20 },
  { name: "Freddy Peralta", positions: "SP", mlb_team: "MIL",
    projections: { "wins" => 11, "saves" => 0, "strikeouts" => 195, "era" => 3.50, "whip" => 1.15 },
    calculated_value: 18 },
  { name: "Pablo López", positions: "SP", mlb_team: "MIN",
    projections: { "wins" => 12, "saves" => 0, "strikeouts" => 180, "era" => 3.45, "whip" => 1.12 },
    calculated_value: 17 },

  # Value Players
  { name: "Luis Arraez", positions: "1B,2B", mlb_team: "SD",
    projections: { "runs" => 80, "home_runs" => 8, "rbi" => 60, "stolen_bases" => 5, "batting_average" => 0.330 },
    calculated_value: 15 },
  { name: "Elly De La Cruz", positions: "SS", mlb_team: "CIN",
    projections: { "runs" => 95, "home_runs" => 20, "rbi" => 70, "stolen_bases" => 60, "batting_average" => 0.250 },
    calculated_value: 25 },
  { name: "Jazz Chisholm Jr.", positions: "OF", mlb_team: "MIA",
    projections: { "runs" => 80, "home_runs" => 22, "rbi" => 70, "stolen_bases" => 35, "batting_average" => 0.255 },
    calculated_value: 20 },
  { name: "Adley Rutschman", positions: "C", mlb_team: "BAL",
    projections: { "runs" => 75, "home_runs" => 20, "rbi" => 80, "stolen_bases" => 5, "batting_average" => 0.275 },
    calculated_value: 19 },
  { name: "Gunnar Henderson", positions: "SS,3B", mlb_team: "BAL",
    projections: { "runs" => 90, "home_runs" => 28, "rbi" => 85, "stolen_bases" => 15, "batting_average" => 0.270 },
    calculated_value: 26 },
  { name: "Julio Rodríguez", positions: "OF", mlb_team: "SEA",
    projections: { "runs" => 90, "home_runs" => 28, "rbi" => 85, "stolen_bases" => 25, "batting_average" => 0.275 },
    calculated_value: 28 },
  { name: "Anthony Volpe", positions: "SS", mlb_team: "NYY",
    projections: { "runs" => 80, "home_runs" => 18, "rbi" => 65, "stolen_bases" => 30, "batting_average" => 0.260 },
    calculated_value: 16 },
]

players = players_data.map do |player_data|
  Player.create!(
    name: player_data[:name],
    positions: player_data[:positions],
    mlb_team: player_data[:mlb_team],
    projections: player_data[:projections],
    calculated_value: player_data[:calculated_value],
    is_drafted: false
  )
end

puts "📜 Creating keeper history for 2025..."
# Add some keeper history from last year
keeper_data = [
  { player_name: "Ronald Acuña Jr.", team_index: 0, price: 38 },
  { player_name: "Shohei Ohtani", team_index: 1, price: 40 },
  { player_name: "Aaron Judge", team_index: 2, price: 35 },
  { player_name: "Spencer Strider", team_index: 3, price: 28 },
  { player_name: "Bobby Witt Jr.", team_index: 4, price: 25 },
  { player_name: "Gerrit Cole", team_index: 5, price: 30 },
]

keeper_data.each do |keeper|
  player = Player.find_by(name: keeper[:player_name])
  next unless player

  KeeperHistory.create!(
    player: player,
    team: teams[keeper[:team_index]],
    year: 2025,
    price: keeper[:price]
  )
end

puts "🎯 Simulating first few draft picks..."
# Simulate the first 6 picks of the draft
draft_picks = [
  { player_name: "Ronald Acuña Jr.", team_index: 0, price: 45, is_keeper: true },
  { player_name: "Shohei Ohtani", team_index: 1, price: 42 },
  { player_name: "Spencer Strider", team_index: 2, price: 35 },
  { player_name: "Aaron Judge", team_index: 3, price: 40 },
  { player_name: "Mookie Betts", team_index: 4, price: 38 },
  { player_name: "Bobby Witt Jr.", team_index: 5, price: 38 },
]

draft_picks.each_with_index do |pick, index|
  player = Player.find_by(name: pick[:player_name])
  next unless player

  DraftPick.create!(
    league: league,
    team: teams[pick[:team_index]],
    player: player,
    price: pick[:price],
    is_keeper: pick[:is_keeper] || false,
    pick_number: index + 1
  )
end

puts "\n✅ Seed data created successfully!"
puts "\n📊 Summary:"
puts "   - 1 League created"
puts "   - #{teams.count} Teams created"
puts "   - #{players.count} Players created"
puts "   - #{KeeperHistory.count} Keeper records from 2025"
puts "   - #{DraftPick.count} Draft picks simulated"
puts "\n🎯 Test the API:"
puts "   curl http://localhost:3639/api/v1/leagues/#{league.id}"
puts "   curl http://localhost:3639/api/v1/players"
puts "   curl http://localhost:3639/api/v1/leagues/#{league.id}/draft_picks"
puts "\n💰 Budget Status:"
Team.all.each do |team|
  puts "   #{team.name}: $#{team.budget_remaining} remaining"
end
