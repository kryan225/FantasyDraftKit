#!/usr/bin/env ruby
# Usage: cd backend && bundle exec rails runner lib/import_2026_roster.rb
#
# Parses the roster overview CSV exported from the fantasy platform and creates:
#   - A new League (2026 Fantasy Baseball)
#   - Teams for each team in the CSV
#   - Player records (or updates existing ones) with partial projections
#   - DraftPick records marked as keepers (is_keeper: true)
#   - KeeperHistory records for the 2025 keeper year
#
# Projection keys are stored using the same field names as DataControlController#import_players
# so that a later full-player CSV import will merge cleanly via name+mlb_team matching.

require "csv"

CSV_PATH = File.expand_path("~/Downloads/roster-overview-all-1-20260325.csv")
LEAGUE_NAME = "2026 Fantasy Baseball"
AUCTION_BUDGET = 260
KEEPER_YEAR = 2025

ROSTER_CONFIG = {
  "C"  => 2, "1B" => 1, "2B" => 1, "3B" => 1, "SS" => 1,
  "MI" => 1, "CI" => 1, "OF" => 5, "UTIL" => 1,
  "SP" => 5, "RP" => 3, "BENCH" => 0
}

# ---------------------------------------------------------------------------
# CSV Parsing
# ---------------------------------------------------------------------------

def parse_player_string(raw)
  return nil unless raw
  parts = raw.strip.split("|")
  return nil unless parts.length == 2

  name_and_pos = parts[0].strip
  mlb_team     = parts[1].strip

  match = name_and_pos.match(/^(.+?)\s+([\w,]+)$/)
  return nil unless match

  name          = match[1].strip
  positions_raw = match[2].strip

  positions = positions_raw.split(",").map(&:strip).filter_map do |pos|
    case pos.upcase
    when "U"  then "UTIL"
    when "DH" then nil
    else pos.upcase
    end
  end.uniq.join(",")

  return nil if positions.empty?
  { name: name, positions: positions, mlb_team: mlb_team }
end

def batter_projections(row)
  {
    "batting_average" => row[9]&.to_f,
    "runs"            => row[10]&.to_i,
    "home_runs"       => row[11]&.to_i,
    "rbi"             => row[12]&.to_i,
    "stolen_bases"    => row[13]&.to_i
  }.compact
end

def pitcher_projections(row)
  {
    "era"         => row[9]&.to_f,
    "whip"        => row[10]&.to_f,
    "wins"        => row[11]&.to_i,
    "strikeouts"  => row[12]&.to_i,
    "saves"       => row[13]&.to_i
  }.compact
end

# ---------------------------------------------------------------------------
# Pass 1 — Parse the CSV into an in-memory structure
# ---------------------------------------------------------------------------

teams_data     = {}   # { "Team Name" => { players: [...] } }
current_team   = nil
current_section = nil # :batters or :pitchers

rows = CSV.parse(File.read(CSV_PATH), liberal_parsing: true)

rows.each do |row|
  first = row[0]&.strip
  next if first.nil? || first.empty?

  # Detect team section headers ("Black Flag Batters", "Black Flag Pitchers")
  if first.match?(/\s+(Batters|Pitchers)\s*$/)
    current_team    = first.sub(/\s+(Batters|Pitchers)\s*$/, "").strip
    current_section = first.include?("Batters") ? :batters : :pitchers
    teams_data[current_team] ||= { players: [] }
    next
  end

  # Skip non-player rows
  next if %w[Pos Reserves Injured].include?(first)
  next if first.start_with?("Active:")
  next if row[1].nil? || row[1].strip.empty?
  next unless current_team && row.length >= 10

  salary = row[7].to_s.strip
  next unless salary.match?(/\A\d+\z/) && salary.to_i > 0

  player_info = parse_player_string(row[1])
  next unless player_info

  roster_slot = (first == "U") ? "UTIL" : first

  projections = (current_section == :batters) ? batter_projections(row) : pitcher_projections(row)

  teams_data[current_team][:players] << {
    roster_slot: roster_slot,
    name:        player_info[:name],
    positions:   player_info[:positions],
    mlb_team:    player_info[:mlb_team],
    salary:      salary.to_i,
    contract:    row[8]&.strip,
    projections: projections
  }
end

# ---------------------------------------------------------------------------
# Dry-run summary
# ---------------------------------------------------------------------------

puts "=" * 60
puts "ROSTER IMPORT SUMMARY"
puts "=" * 60
puts "League:  #{LEAGUE_NAME}"
puts "Budget:  $#{AUCTION_BUDGET}"
puts "Teams:   #{teams_data.size}"
puts

teams_data.each do |team_name, data|
  total_salary = data[:players].sum { |p| p[:salary] }
  puts "  #{team_name} (#{data[:players].size} keepers, $#{total_salary} committed)"
  data[:players].each do |p|
    puts "    #{p[:roster_slot].ljust(4)} #{p[:name]} (#{p[:positions]}) | #{p[:mlb_team]} - $#{p[:salary]}"
  end
end

puts
puts "=" * 60

# ---------------------------------------------------------------------------
# Pass 2 — Create records inside a transaction
# ---------------------------------------------------------------------------

ActiveRecord::Base.transaction do
  league = League.create!(
    name:           LEAGUE_NAME,
    team_count:     teams_data.size,
    auction_budget: AUCTION_BUDGET,
    keeper_limit:   10,
    roster_config:  ROSTER_CONFIG
  )
  puts "\nCreated league: #{league.name} (id=#{league.id})"

  pick_number    = 1
  players_created = 0
  players_updated = 0

  teams_data.each do |team_name, team_data|
    team = Team.create!(league: league, name: team_name)

    team_data[:players].each do |pd|
      # Find existing player by name + mlb_team (same matching as DataControlController)
      player = Player.find_by(name: pd[:name], mlb_team: pd[:mlb_team])

      if player
        merged = (player.projections || {}).merge(pd[:projections])
        merged_positions = (player.positions.to_s.split(",") | pd[:positions].split(",")).join(",")
        player.update_columns(projections: merged, positions: merged_positions)
        puts "    MERGED: #{pd[:name]} (#{pd[:mlb_team]})"
        players_updated += 1
      else
        player = Player.create!(
          name:             pd[:name],
          positions:        pd[:positions],
          mlb_team:         pd[:mlb_team],
          projections:      pd[:projections],
          calculated_value: 0,
          is_drafted:       false
        )
        players_created += 1
      end

      # DraftPick — skip validations (roster-slot limits, position-eligibility)
      # Callbacks still fire: budget deducted, player marked drafted.
      draft_pick = DraftPick.new(
        league:           league,
        team:             team,
        player:           player,
        price:            pd[:salary],
        is_keeper:        true,
        pick_number:      pick_number,
        drafted_position: pd[:roster_slot]
      )
      draft_pick.save!(validate: false)
      pick_number += 1

      # KeeperHistory
      KeeperHistory.create!(
        player: player,
        team:   team,
        year:   KEEPER_YEAR,
        price:  pd[:salary]
      )
    end

    team.reload
    puts "  #{team.name}: #{team_data[:players].size} keepers, budget remaining $#{team.budget_remaining}"
  end

  puts
  puts "=" * 60
  puts "IMPORT COMPLETE"
  puts "=" * 60
  puts "  League:           #{league.name} (id=#{league.id})"
  puts "  Teams:            #{league.teams.count}"
  puts "  Players created:  #{players_created}"
  puts "  Players updated:  #{players_updated}"
  puts "  Keeper picks:     #{league.draft_picks.keepers.count}"
  puts "  Keeper histories: #{KeeperHistory.where(team: league.teams).count}"
  puts
  puts "Open http://localhost:3639/leagues/#{league.id} to view the league."
end
