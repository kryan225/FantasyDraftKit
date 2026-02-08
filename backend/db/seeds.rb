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
    "C" => 2,
    "1B" => 1,
    "2B" => 1,
    "3B" => 1,
    "SS" => 1,
    "MI" => 1,
    "CI" => 1,
    "OF" => 5,
    "UTIL" => 2,
    "SP" => 5,
    "RP" => 3,
    "BENCH" => 0
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

  # Additional Catchers
  { name: "Will Smith", positions: "C", mlb_team: "LAD",
    projections: { "runs" => 70, "home_runs" => 20, "rbi" => 75, "stolen_bases" => 3, "batting_average" => 0.265 },
    calculated_value: 18 },
  { name: "Salvador Perez", positions: "C", mlb_team: "KC",
    projections: { "runs" => 60, "home_runs" => 25, "rbi" => 85, "stolen_bases" => 0, "batting_average" => 0.250 },
    calculated_value: 15 },
  { name: "Sean Murphy", positions: "C", mlb_team: "ATL",
    projections: { "runs" => 65, "home_runs" => 18, "rbi" => 70, "stolen_bases" => 2, "batting_average" => 0.260 },
    calculated_value: 14 },

  # Additional First Basemen
  { name: "Freddie Freeman", positions: "1B", mlb_team: "LAD",
    projections: { "runs" => 95, "home_runs" => 28, "rbi" => 100, "stolen_bases" => 8, "batting_average" => 0.295 },
    calculated_value: 30 },
  { name: "Yandy Díaz", positions: "1B,3B", mlb_team: "TB",
    projections: { "runs" => 75, "home_runs" => 18, "rbi" => 75, "stolen_bases" => 3, "batting_average" => 0.300 },
    calculated_value: 17 },
  { name: "Josh Naylor", positions: "1B", mlb_team: "CLE",
    projections: { "runs" => 70, "home_runs" => 26, "rbi" => 90, "stolen_bases" => 1, "batting_average" => 0.265 },
    calculated_value: 16 },

  # Additional Second Basemen
  { name: "Marcus Semien", positions: "2B", mlb_team: "TEX",
    projections: { "runs" => 100, "home_runs" => 25, "rbi" => 85, "stolen_bases" => 15, "batting_average" => 0.270 },
    calculated_value: 24 },
  { name: "Gleyber Torres", positions: "2B", mlb_team: "NYY",
    projections: { "runs" => 80, "home_runs" => 22, "rbi" => 75, "stolen_bases" => 8, "batting_average" => 0.275 },
    calculated_value: 18 },
  { name: "Ozzie Albies", positions: "2B", mlb_team: "ATL",
    projections: { "runs" => 90, "home_runs" => 24, "rbi" => 80, "stolen_bases" => 18, "batting_average" => 0.280 },
    calculated_value: 22 },

  # Additional Third Basemen
  { name: "Austin Riley", positions: "3B", mlb_team: "ATL",
    projections: { "runs" => 85, "home_runs" => 30, "rbi" => 95, "stolen_bases" => 2, "batting_average" => 0.270 },
    calculated_value: 25 },
  { name: "José Ramírez", positions: "3B", mlb_team: "CLE",
    projections: { "runs" => 100, "home_runs" => 28, "rbi" => 90, "stolen_bases" => 25, "batting_average" => 0.285 },
    calculated_value: 32 },
  { name: "Manny Machado", positions: "3B,SS", mlb_team: "SD",
    projections: { "runs" => 85, "home_runs" => 28, "rbi" => 90, "stolen_bases" => 8, "batting_average" => 0.275 },
    calculated_value: 26 },

  # Additional Shortstops
  { name: "Trea Turner", positions: "SS", mlb_team: "PHI",
    projections: { "runs" => 95, "home_runs" => 22, "rbi" => 75, "stolen_bases" => 28, "batting_average" => 0.285 },
    calculated_value: 27 },
  { name: "Francisco Lindor", positions: "SS", mlb_team: "NYM",
    projections: { "runs" => 90, "home_runs" => 26, "rbi" => 85, "stolen_bases" => 18, "batting_average" => 0.270 },
    calculated_value: 26 },
  { name: "Xander Bogaerts", positions: "SS", mlb_team: "SD",
    projections: { "runs" => 80, "home_runs" => 20, "rbi" => 80, "stolen_bases" => 8, "batting_average" => 0.280 },
    calculated_value: 20 },

  # Additional Outfielders
  { name: "Fernando Tatis Jr.", positions: "OF", mlb_team: "SD",
    projections: { "runs" => 100, "home_runs" => 35, "rbi" => 95, "stolen_bases" => 25, "batting_average" => 0.280 },
    calculated_value: 35 },
  { name: "Juan Soto", positions: "OF", mlb_team: "NYY",
    projections: { "runs" => 100, "home_runs" => 32, "rbi" => 95, "stolen_bases" => 10, "batting_average" => 0.285 },
    calculated_value: 33 },
  { name: "Yordan Alvarez", positions: "OF,DH", mlb_team: "HOU",
    projections: { "runs" => 85, "home_runs" => 35, "rbi" => 105, "stolen_bases" => 2, "batting_average" => 0.290 },
    calculated_value: 30 },
  { name: "Randy Arozarena", positions: "OF", mlb_team: "TB",
    projections: { "runs" => 85, "home_runs" => 22, "rbi" => 75, "stolen_bases" => 25, "batting_average" => 0.265 },
    calculated_value: 22 },
  { name: "Teoscar Hernández", positions: "OF", mlb_team: "LAD",
    projections: { "runs" => 75, "home_runs" => 28, "rbi" => 90, "stolen_bases" => 8, "batting_average" => 0.260 },
    calculated_value: 20 },
  { name: "Luis Robert Jr.", positions: "OF", mlb_team: "CWS",
    projections: { "runs" => 80, "home_runs" => 30, "rbi" => 85, "stolen_bases" => 18, "batting_average" => 0.270 },
    calculated_value: 24 },
  { name: "Cedric Mullins", positions: "OF", mlb_team: "BAL",
    projections: { "runs" => 85, "home_runs" => 18, "rbi" => 65, "stolen_bases" => 30, "batting_average" => 0.265 },
    calculated_value: 19 },
  { name: "Byron Buxton", positions: "OF", mlb_team: "MIN",
    projections: { "runs" => 70, "home_runs" => 25, "rbi" => 70, "stolen_bases" => 15, "batting_average" => 0.255 },
    calculated_value: 18 },
  { name: "Michael Harris II", positions: "OF", mlb_team: "ATL",
    projections: { "runs" => 80, "home_runs" => 20, "rbi" => 70, "stolen_bases" => 20, "batting_average" => 0.275 },
    calculated_value: 20 },
  { name: "Riley Greene", positions: "OF", mlb_team: "DET",
    projections: { "runs" => 75, "home_runs" => 22, "rbi" => 75, "stolen_bases" => 12, "batting_average" => 0.270 },
    calculated_value: 18 },

  # Additional Starting Pitchers
  { name: "Shane Bieber", positions: "SP", mlb_team: "CLE",
    projections: { "wins" => 14, "saves" => 0, "strikeouts" => 210, "era" => 3.15, "whip" => 1.08 },
    calculated_value: 25 },
  { name: "Kevin Gausman", positions: "SP", mlb_team: "TOR",
    projections: { "wins" => 13, "saves" => 0, "strikeouts" => 195, "era" => 3.25, "whip" => 1.10 },
    calculated_value: 22 },
  { name: "Sonny Gray", positions: "SP", mlb_team: "STL",
    projections: { "wins" => 12, "saves" => 0, "strikeouts" => 185, "era" => 3.30, "whip" => 1.12 },
    calculated_value: 20 },
  { name: "Luis Castillo", positions: "SP", mlb_team: "SEA",
    projections: { "wins" => 13, "saves" => 0, "strikeouts" => 190, "era" => 3.20, "whip" => 1.09 },
    calculated_value: 21 },
  { name: "George Kirby", positions: "SP", mlb_team: "SEA",
    projections: { "wins" => 12, "saves" => 0, "strikeouts" => 180, "era" => 3.35, "whip" => 1.11 },
    calculated_value: 19 },
  { name: "Hunter Greene", positions: "SP", mlb_team: "CIN",
    projections: { "wins" => 11, "saves" => 0, "strikeouts" => 200, "era" => 3.50, "whip" => 1.15 },
    calculated_value: 18 },
  { name: "Cristian Javier", positions: "SP", mlb_team: "HOU",
    projections: { "wins" => 11, "saves" => 0, "strikeouts" => 175, "era" => 3.40, "whip" => 1.13 },
    calculated_value: 17 },
  { name: "Framber Valdez", positions: "SP", mlb_team: "HOU",
    projections: { "wins" => 14, "saves" => 0, "strikeouts" => 170, "era" => 3.30, "whip" => 1.14 },
    calculated_value: 19 },

  # Additional Relief Pitchers
  { name: "Josh Hader", positions: "RP", mlb_team: "HOU",
    projections: { "wins" => 4, "saves" => 36, "strikeouts" => 90, "era" => 2.70, "whip" => 1.02 },
    calculated_value: 19 },
  { name: "Devin Williams", positions: "RP", mlb_team: "MIL",
    projections: { "wins" => 5, "saves" => 32, "strikeouts" => 85, "era" => 2.85, "whip" => 1.08 },
    calculated_value: 17 },
  { name: "Alexis Díaz", positions: "RP", mlb_team: "CIN",
    projections: { "wins" => 4, "saves" => 30, "strikeouts" => 75, "era" => 2.90, "whip" => 1.10 },
    calculated_value: 15 },
  { name: "Jordan Romano", positions: "RP", mlb_team: "TOR",
    projections: { "wins" => 3, "saves" => 34, "strikeouts" => 80, "era" => 2.75, "whip" => 1.05 },
    calculated_value: 16 },
  { name: "Clay Holmes", positions: "RP", mlb_team: "NYY",
    projections: { "wins" => 4, "saves" => 28, "strikeouts" => 70, "era" => 3.00, "whip" => 1.12 },
    calculated_value: 14 },
  { name: "Edwin Díaz", positions: "RP", mlb_team: "NYM",
    projections: { "wins" => 3, "saves" => 35, "strikeouts" => 95, "era" => 2.60, "whip" => 1.00 },
    calculated_value: 18 },

  # Additional Available Players for Drafting
  # More Catchers
  { name: "Willson Contreras", positions: "C", mlb_team: "STL",
    projections: { "runs" => 65, "home_runs" => 19, "rbi" => 70, "stolen_bases" => 3, "batting_average" => 0.265 },
    calculated_value: 14 },
  { name: "Cal Raleigh", positions: "C", mlb_team: "SEA",
    projections: { "runs" => 60, "home_runs" => 24, "rbi" => 75, "stolen_bases" => 1, "batting_average" => 0.245 },
    calculated_value: 13 },
  { name: "Gabriel Moreno", positions: "C", mlb_team: "ARI",
    projections: { "runs" => 55, "home_runs" => 12, "rbi" => 60, "stolen_bases" => 8, "batting_average" => 0.280 },
    calculated_value: 11 },
  { name: "Jonah Heim", positions: "C", mlb_team: "TEX",
    projections: { "runs" => 50, "home_runs" => 16, "rbi" => 65, "stolen_bases" => 2, "batting_average" => 0.255 },
    calculated_value: 10 },

  # More First Basemen
  { name: "Christian Walker", positions: "1B", mlb_team: "ARI",
    projections: { "runs" => 75, "home_runs" => 30, "rbi" => 95, "stolen_bases" => 2, "batting_average" => 0.265 },
    calculated_value: 19 },
  { name: "Triston Casas", positions: "1B", mlb_team: "BOS",
    projections: { "runs" => 70, "home_runs" => 24, "rbi" => 80, "stolen_bases" => 3, "batting_average" => 0.260 },
    calculated_value: 16 },
  { name: "Spencer Torkelson", positions: "1B", mlb_team: "DET",
    projections: { "runs" => 65, "home_runs" => 26, "rbi" => 85, "stolen_bases" => 1, "batting_average" => 0.250 },
    calculated_value: 15 },
  { name: "Ryan Mountcastle", positions: "1B", mlb_team: "BAL",
    projections: { "runs" => 60, "home_runs" => 22, "rbi" => 75, "stolen_bases" => 2, "batting_average" => 0.255 },
    calculated_value: 13 },

  # More Second Basemen
  { name: "Ketel Marte", positions: "2B,OF", mlb_team: "ARI",
    projections: { "runs" => 80, "home_runs" => 20, "rbi" => 75, "stolen_bases" => 12, "batting_average" => 0.285 },
    calculated_value: 20 },
  { name: "Jorge Polanco", positions: "2B", mlb_team: "SEA",
    projections: { "runs" => 70, "home_runs" => 18, "rbi" => 70, "stolen_bases" => 8, "batting_average" => 0.270 },
    calculated_value: 14 },
  { name: "Andrés Giménez", positions: "2B", mlb_team: "CLE",
    projections: { "runs" => 75, "home_runs" => 14, "rbi" => 60, "stolen_bases" => 20, "batting_average" => 0.265 },
    calculated_value: 15 },
  { name: "Nico Hoerner", positions: "2B", mlb_team: "CHC",
    projections: { "runs" => 70, "home_runs" => 10, "rbi" => 55, "stolen_bases" => 15, "batting_average" => 0.285 },
    calculated_value: 13 },
  { name: "Brandon Lowe", positions: "2B", mlb_team: "TB",
    projections: { "runs" => 70, "home_runs" => 22, "rbi" => 70, "stolen_bases" => 5, "batting_average" => 0.250 },
    calculated_value: 14 },

  # More Third Basemen
  { name: "Nolan Arenado", positions: "3B", mlb_team: "STL",
    projections: { "runs" => 75, "home_runs" => 26, "rbi" => 90, "stolen_bases" => 2, "batting_average" => 0.270 },
    calculated_value: 20 },
  { name: "Ke'Bryan Hayes", positions: "3B", mlb_team: "PIT",
    projections: { "runs" => 70, "home_runs" => 16, "rbi" => 65, "stolen_bases" => 10, "batting_average" => 0.275 },
    calculated_value: 14 },
  { name: "Isaac Paredes", positions: "3B", mlb_team: "TB",
    projections: { "runs" => 65, "home_runs" => 24, "rbi" => 75, "stolen_bases" => 2, "batting_average" => 0.260 },
    calculated_value: 15 },
  { name: "Eugenio Suárez", positions: "3B", mlb_team: "ARI",
    projections: { "runs" => 70, "home_runs" => 25, "rbi" => 85, "stolen_bases" => 1, "batting_average" => 0.245 },
    calculated_value: 14 },

  # More Shortstops
  { name: "Carlos Correa", positions: "SS", mlb_team: "MIN",
    projections: { "runs" => 75, "home_runs" => 22, "rbi" => 80, "stolen_bases" => 5, "batting_average" => 0.275 },
    calculated_value: 18 },
  { name: "Dansby Swanson", positions: "SS", mlb_team: "CHC",
    projections: { "runs" => 75, "home_runs" => 20, "rbi" => 75, "stolen_bases" => 10, "batting_average" => 0.265 },
    calculated_value: 17 },
  { name: "Jeremy Peña", positions: "SS", mlb_team: "HOU",
    projections: { "runs" => 70, "home_runs" => 18, "rbi" => 65, "stolen_bases" => 12, "batting_average" => 0.260 },
    calculated_value: 14 },
  { name: "Willy Adames", positions: "SS", mlb_team: "MIL",
    projections: { "runs" => 75, "home_runs" => 24, "rbi" => 80, "stolen_bases" => 8, "batting_average" => 0.255 },
    calculated_value: 17 },
  { name: "CJ Abrams", positions: "SS", mlb_team: "WAS",
    projections: { "runs" => 80, "home_runs" => 16, "rbi" => 60, "stolen_bases" => 35, "batting_average" => 0.270 },
    calculated_value: 18 },

  # More Outfielders
  { name: "Corbin Carroll", positions: "OF", mlb_team: "ARI",
    projections: { "runs" => 95, "home_runs" => 24, "rbi" => 75, "stolen_bases" => 40, "batting_average" => 0.270 },
    calculated_value: 28 },
  { name: "Jarren Duran", positions: "OF", mlb_team: "BOS",
    projections: { "runs" => 85, "home_runs" => 18, "rbi" => 65, "stolen_bases" => 30, "batting_average" => 0.275 },
    calculated_value: 20 },
  { name: "Bryan Reynolds", positions: "OF", mlb_team: "PIT",
    projections: { "runs" => 75, "home_runs" => 20, "rbi" => 75, "stolen_bases" => 10, "batting_average" => 0.280 },
    calculated_value: 18 },
  { name: "Seiya Suzuki", positions: "OF", mlb_team: "CHC",
    projections: { "runs" => 75, "home_runs" => 22, "rbi" => 80, "stolen_bases" => 8, "batting_average" => 0.270 },
    calculated_value: 18 },
  { name: "Lane Thomas", positions: "OF", mlb_team: "WAS",
    projections: { "runs" => 70, "home_runs" => 20, "rbi" => 70, "stolen_bases" => 15, "batting_average" => 0.265 },
    calculated_value: 16 },
  { name: "Tyler O'Neill", positions: "OF", mlb_team: "BOS",
    projections: { "runs" => 65, "home_runs" => 28, "rbi" => 85, "stolen_bases" => 5, "batting_average" => 0.250 },
    calculated_value: 17 },
  { name: "Anthony Santander", positions: "OF", mlb_team: "BAL",
    projections: { "runs" => 70, "home_runs" => 26, "rbi" => 85, "stolen_bases" => 3, "batting_average" => 0.260 },
    calculated_value: 17 },
  { name: "Jeff McNeil", positions: "OF,2B", mlb_team: "NYM",
    projections: { "runs" => 70, "home_runs" => 12, "rbi" => 60, "stolen_bases" => 8, "batting_average" => 0.295 },
    calculated_value: 13 },
  { name: "Lourdes Gurriel Jr.", positions: "OF", mlb_team: "ARI",
    projections: { "runs" => 70, "home_runs" => 20, "rbi" => 75, "stolen_bases" => 8, "batting_average" => 0.270 },
    calculated_value: 15 },
  { name: "Max Kepler", positions: "OF", mlb_team: "MIN",
    projections: { "runs" => 65, "home_runs" => 22, "rbi" => 70, "stolen_bases" => 5, "batting_average" => 0.255 },
    calculated_value: 14 },
  { name: "Whit Merrifield", positions: "OF,2B", mlb_team: "PHI",
    projections: { "runs" => 70, "home_runs" => 10, "rbi" => 55, "stolen_bases" => 20, "batting_average" => 0.275 },
    calculated_value: 12 },
  { name: "Esteury Ruiz", positions: "OF", mlb_team: "OAK",
    projections: { "runs" => 75, "home_runs" => 8, "rbi" => 45, "stolen_bases" => 50, "batting_average" => 0.250 },
    calculated_value: 15 },
  { name: "Masataka Yoshida", positions: "OF", mlb_team: "BOS",
    projections: { "runs" => 75, "home_runs" => 16, "rbi" => 70, "stolen_bases" => 5, "batting_average" => 0.285 },
    calculated_value: 15 },
  { name: "Jesse Winker", positions: "OF", mlb_team: "NYM",
    projections: { "runs" => 65, "home_runs" => 18, "rbi" => 65, "stolen_bases" => 3, "batting_average" => 0.265 },
    calculated_value: 12 },
  { name: "Lars Nootbaar", positions: "OF", mlb_team: "STL",
    projections: { "runs" => 70, "home_runs" => 16, "rbi" => 65, "stolen_bases" => 10, "batting_average" => 0.270 },
    calculated_value: 14 },

  # More Starting Pitchers
  { name: "Joe Ryan", positions: "SP", mlb_team: "MIN",
    projections: { "wins" => 11, "saves" => 0, "strikeouts" => 175, "era" => 3.55, "whip" => 1.16 },
    calculated_value: 16 },
  { name: "Clayton Kershaw", positions: "SP", mlb_team: "LAD",
    projections: { "wins" => 10, "saves" => 0, "strikeouts" => 150, "era" => 3.40, "whip" => 1.10 },
    calculated_value: 15 },
  { name: "Yusei Kikuchi", positions: "SP", mlb_team: "TOR",
    projections: { "wins" => 10, "saves" => 0, "strikeouts" => 170, "era" => 3.60, "whip" => 1.18 },
    calculated_value: 14 },
  { name: "Kodai Senga", positions: "SP", mlb_team: "NYM",
    projections: { "wins" => 11, "saves" => 0, "strikeouts" => 185, "era" => 3.45, "whip" => 1.15 },
    calculated_value: 16 },
  { name: "Bryce Miller", positions: "SP", mlb_team: "SEA",
    projections: { "wins" => 10, "saves" => 0, "strikeouts" => 165, "era" => 3.50, "whip" => 1.14 },
    calculated_value: 15 },
  { name: "Mitch Keller", positions: "SP", mlb_team: "PIT",
    projections: { "wins" => 11, "saves" => 0, "strikeouts" => 170, "era" => 3.45, "whip" => 1.13 },
    calculated_value: 16 },
  { name: "Tanner Bibee", positions: "SP", mlb_team: "CLE",
    projections: { "wins" => 10, "saves" => 0, "strikeouts" => 165, "era" => 3.55, "whip" => 1.16 },
    calculated_value: 14 },
  { name: "Taj Bradley", positions: "SP", mlb_team: "TB",
    projections: { "wins" => 9, "saves" => 0, "strikeouts" => 175, "era" => 3.65, "whip" => 1.20 },
    calculated_value: 13 },
  { name: "Reid Detmers", positions: "SP", mlb_team: "LAA",
    projections: { "wins" => 9, "saves" => 0, "strikeouts" => 160, "era" => 3.70, "whip" => 1.22 },
    calculated_value: 12 },
  { name: "Tyler Glasnow", positions: "SP", mlb_team: "LAD",
    projections: { "wins" => 12, "saves" => 0, "strikeouts" => 190, "era" => 3.25, "whip" => 1.08 },
    calculated_value: 20 },
  { name: "Bailey Ober", positions: "SP", mlb_team: "MIN",
    projections: { "wins" => 10, "saves" => 0, "strikeouts" => 160, "era" => 3.60, "whip" => 1.17 },
    calculated_value: 13 },
  { name: "Gavin Stone", positions: "SP", mlb_team: "LAD",
    projections: { "wins" => 9, "saves" => 0, "strikeouts" => 150, "era" => 3.65, "whip" => 1.18 },
    calculated_value: 12 },
  { name: "Andrew Abbott", positions: "SP", mlb_team: "CIN",
    projections: { "wins" => 9, "saves" => 0, "strikeouts" => 155, "era" => 3.70, "whip" => 1.20 },
    calculated_value: 11 },
  { name: "Merrill Kelly", positions: "SP", mlb_team: "ARI",
    projections: { "wins" => 11, "saves" => 0, "strikeouts" => 165, "era" => 3.50, "whip" => 1.14 },
    calculated_value: 15 },

  # More Relief Pitchers
  { name: "Andrés Muñoz", positions: "RP", mlb_team: "SEA",
    projections: { "wins" => 4, "saves" => 30, "strikeouts" => 80, "era" => 2.85, "whip" => 1.08 },
    calculated_value: 15 },
  { name: "Camilo Doval", positions: "RP", mlb_team: "SF",
    projections: { "wins" => 3, "saves" => 28, "strikeouts" => 75, "era" => 3.00, "whip" => 1.15 },
    calculated_value: 13 },
  { name: "Robert Suarez", positions: "RP", mlb_team: "SD",
    projections: { "wins" => 4, "saves" => 26, "strikeouts" => 70, "era" => 2.95, "whip" => 1.10 },
    calculated_value: 13 },
  { name: "David Bednar", positions: "RP", mlb_team: "PIT",
    projections: { "wins" => 3, "saves" => 27, "strikeouts" => 72, "era" => 2.90, "whip" => 1.12 },
    calculated_value: 13 },
  { name: "Paul Sewald", positions: "RP", mlb_team: "ARI",
    projections: { "wins" => 3, "saves" => 25, "strikeouts" => 70, "era" => 3.05, "whip" => 1.14 },
    calculated_value: 12 },
  { name: "Pete Fairbanks", positions: "RP", mlb_team: "TB",
    projections: { "wins" => 3, "saves" => 24, "strikeouts" => 68, "era" => 3.10, "whip" => 1.16 },
    calculated_value: 11 },
  { name: "Jason Adam", positions: "RP", mlb_team: "TB",
    projections: { "wins" => 5, "saves" => 8, "strikeouts" => 75, "era" => 2.95, "whip" => 1.10 },
    calculated_value: 9 },
  { name: "Matt Brash", positions: "RP", mlb_team: "SEA",
    projections: { "wins" => 4, "saves" => 10, "strikeouts" => 85, "era" => 3.00, "whip" => 1.15 },
    calculated_value: 10 },
  { name: "Kyle Finnegan", positions: "RP", mlb_team: "WAS",
    projections: { "wins" => 3, "saves" => 22, "strikeouts" => 65, "era" => 3.15, "whip" => 1.18 },
    calculated_value: 10 },
  { name: "Jhoan Duran", positions: "RP", mlb_team: "MIN",
    projections: { "wins" => 4, "saves" => 20, "strikeouts" => 80, "era" => 2.90, "whip" => 1.08 },
    calculated_value: 12 },
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

puts "🎯 Simulating draft with partially filled rosters..."
# Create varied draft picks across teams - some teams well into their draft, some just starting
draft_picks = [
  # Team 0 (Bombers) - 12 players (roughly half full)
  { player_name: "Ronald Acuña Jr.", team_index: 0, price: 45, is_keeper: true, position: "OF" },
  { player_name: "J.T. Realmuto", team_index: 0, price: 22, position: "C" },
  { player_name: "Pete Alonso", team_index: 0, price: 28, position: "1B" },
  { player_name: "Jose Altuve", team_index: 0, price: 25, position: "2B" },
  { player_name: "Gerrit Cole", team_index: 0, price: 32, position: "SP" },
  { player_name: "Corbin Burnes", team_index: 0, price: 30, position: "SP" },
  { player_name: "Emmanuel Clase", team_index: 0, price: 20, position: "RP" },
  { player_name: "Kyle Tucker", team_index: 0, price: 30, position: "OF" },
  { player_name: "Cedric Mullins", team_index: 0, price: 19, position: "OF" },
  { player_name: "Shane Bieber", team_index: 0, price: 25, position: "SP" },
  { player_name: "Josh Hader", team_index: 0, price: 19, position: "RP" },
  { player_name: "Luis Arraez", team_index: 0, price: 15, position: "UTIL" },

  # Team 1 (Sluggers) - 8 players (early in draft)
  { player_name: "Shohei Ohtani", team_index: 1, price: 42, position: "OF" },
  { player_name: "Vladimir Guerrero Jr.", team_index: 1, price: 32, position: "1B" },
  { player_name: "Bobby Witt Jr.", team_index: 1, price: 38, position: "SS" },
  { player_name: "Spencer Strider", team_index: 1, price: 35, position: "SP" },
  { player_name: "Tarik Skubal", team_index: 1, price: 26, position: "SP" },
  { player_name: "Félix Bautista", team_index: 1, price: 18, position: "RP" },
  { player_name: "Juan Soto", team_index: 1, price: 33, position: "OF" },
  { player_name: "Marcus Semien", team_index: 1, price: 24, position: "2B" },

  # Team 2 (Dingers) - 15 players (well into draft)
  { player_name: "Aaron Judge", team_index: 2, price: 40, position: "OF" },
  { player_name: "Mookie Betts", team_index: 2, price: 38, position: "OF" },
  { player_name: "Freddie Freeman", team_index: 2, price: 30, position: "1B" },
  { player_name: "Manny Machado", team_index: 2, price: 26, position: "3B" },
  { player_name: "Trea Turner", team_index: 2, price: 27, position: "SS" },
  { player_name: "Ozzie Albies", team_index: 2, price: 22, position: "2B" },
  { player_name: "Will Smith", team_index: 2, price: 18, position: "C" },
  { player_name: "Zack Wheeler", team_index: 2, price: 24, position: "SP" },
  { player_name: "Blake Snell", team_index: 2, price: 22, position: "SP" },
  { player_name: "Dylan Cease", team_index: 2, price: 21, position: "SP" },
  { player_name: "Ryan Helsley", team_index: 2, price: 19, position: "RP" },
  { player_name: "Devin Williams", team_index: 2, price: 17, position: "RP" },
  { player_name: "Fernando Tatis Jr.", team_index: 2, price: 35, position: "OF" },
  { player_name: "Luis Robert Jr.", team_index: 2, price: 24, position: "UTIL" },
  { player_name: "Kevin Gausman", team_index: 2, price: 22, position: "SP" },

  # Team 3 (Aces) - 10 players (midway through draft)
  { player_name: "Julio Rodríguez", team_index: 3, price: 28, position: "OF" },
  { player_name: "José Ramírez", team_index: 3, price: 32, position: "3B" },
  { player_name: "Corey Seager", team_index: 3, price: 26, position: "SS" },
  { player_name: "Matt Olson", team_index: 3, price: 28, position: "1B" },
  { player_name: "Adley Rutschman", team_index: 3, price: 19, position: "C" },
  { player_name: "Logan Webb", team_index: 3, price: 20, position: "SP" },
  { player_name: "Freddy Peralta", team_index: 3, price: 18, position: "SP" },
  { player_name: "Edwin Díaz", team_index: 3, price: 18, position: "RP" },
  { player_name: "Yordan Alvarez", team_index: 3, price: 30, position: "OF" },
  { player_name: "Gleyber Torres", team_index: 3, price: 18, position: "2B" },

  # Team 4 (Mavericks) - 5 players (just started)
  { player_name: "Gunnar Henderson", team_index: 4, price: 26, position: "SS" },
  { player_name: "Rafael Devers", team_index: 4, price: 27, position: "3B" },
  { player_name: "Pablo López", team_index: 4, price: 17, position: "SP" },
  { player_name: "Jazz Chisholm Jr.", team_index: 4, price: 20, position: "OF" },
  { player_name: "Jordan Romano", team_index: 4, price: 16, position: "RP" },

  # Team 5 (Thunder) - 6 players
  { player_name: "Bo Bichette", team_index: 5, price: 24, position: "SS" },
  { player_name: "Austin Riley", team_index: 5, price: 25, position: "3B" },
  { player_name: "Salvador Perez", team_index: 5, price: 15, position: "C" },
  { player_name: "Luis Castillo", team_index: 5, price: 21, position: "SP" },
  { player_name: "Sonny Gray", team_index: 5, price: 20, position: "SP" },
  { player_name: "Randy Arozarena", team_index: 5, price: 22, position: "OF" },

  # Team 6 (Storm) - 3 players (minimal)
  { player_name: "Elly De La Cruz", team_index: 6, price: 25, position: "SS" },
  { player_name: "George Kirby", team_index: 6, price: 19, position: "SP" },
  { player_name: "Alexis Díaz", team_index: 6, price: 15, position: "RP" },

  # Team 7 (Titans) - 9 players
  { player_name: "Francisco Lindor", team_index: 7, price: 26, position: "SS" },
  { player_name: "Yandy Díaz", team_index: 7, price: 17, position: "1B" },
  { player_name: "Sean Murphy", team_index: 7, price: 14, position: "C" },
  { player_name: "Michael Harris II", team_index: 7, price: 20, position: "OF" },
  { player_name: "Teoscar Hernández", team_index: 7, price: 20, position: "OF" },
  { player_name: "Hunter Greene", team_index: 7, price: 18, position: "SP" },
  { player_name: "Cristian Javier", team_index: 7, price: 17, position: "SP" },
  { player_name: "Clay Holmes", team_index: 7, price: 14, position: "RP" },
  { player_name: "Riley Greene", team_index: 7, price: 18, position: "OF" },

  # Team 8-11 have no picks yet (showing variety in draft progress)

  # Complete Team 2 (Dingers) roster - filling remaining 8 slots with $13 budget
  # With new config: need 1 more C, 2 more OF, 1 MI, 1 CI (no BENCH)
  { player_name: "Merrill Kelly", team_index: 2, price: 3, position: "SP" },
  { player_name: "Camilo Doval", team_index: 2, price: 2, position: "RP" },
  { player_name: "Ketel Marte", team_index: 2, price: 2, position: "UTIL" },
  { player_name: "Jarren Duran", team_index: 2, price: 2, position: "OF" },
  { player_name: "Bryan Reynolds", team_index: 2, price: 2, position: "OF" },
  { player_name: "Brandon Lowe", team_index: 2, price: 2, position: "MI" },
  { player_name: "Willson Contreras", team_index: 2, price: 2, position: "C" },
  { player_name: "Christian Walker", team_index: 2, price: 2, position: "CI" },
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
    pick_number: index + 1,
    drafted_position: pick[:position]
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
