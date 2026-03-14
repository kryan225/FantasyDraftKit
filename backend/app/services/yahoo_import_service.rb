# frozen_string_literal: true

require 'csv'

# YahooImportService
#
# Imports player projections from Yahoo fantasy baseball CSV exports.
# Auto-detects hitter vs pitcher CSV from the header row.
# Merges two-way players (e.g., Ohtani) when a matching name+team already exists.
#
# Usage:
#   result = YahooImportService.new(file_path).call
#   # => { imported: 42, merged: 1, merged_names: ["Shohei Ohtani"] }
#
class YahooImportService
  attr_reader :file_path

  def initialize(file_path)
    @file_path = file_path
  end

  def call
    imported_count = 0
    merged_count = 0
    merged_names = []
    csv_type = nil

    CSV.foreach(file_path, headers: false, encoding: 'UTF-8') do |row|
      first_cell = row[0]&.strip

      next if first_cell&.include?("All Players")

      if first_cell == "Avail"
        csv_type = row[2]&.strip == "AB" ? :hitter : :pitcher
        next
      end

      next if row[1].nil? || row[1].strip.empty?

      player_name, positions, mlb_team = parse_player_info(row[1])
      next unless player_name && positions && mlb_team

      projections = csv_type == :pitcher ? parse_pitcher_stats(row) : parse_hitter_stats(row)

      existing_player = Player.find_by(name: player_name, mlb_team: mlb_team)
      if existing_player
        merged_projections = (existing_player.projections || {}).merge(projections)
        merged_positions = (existing_player.positions.to_s.split(',') | positions.split(',')).join(',')
        existing_player.update!(projections: merged_projections, positions: merged_positions)
        merged_names << player_name
        merged_count += 1
        next
      end

      Player.create!(
        name: player_name,
        positions: positions,
        mlb_team: mlb_team,
        projections: projections,
        calculated_value: 0,
        is_drafted: false
      )

      imported_count += 1
    end

    { imported: imported_count, merged: merged_count, merged_names: merged_names }
  end

  private

  def parse_player_info(player_string)
    return [nil, nil, nil] unless player_string

    parts = player_string.split("|")
    return [nil, nil, nil] unless parts.length == 2

    name_and_positions = parts[0].strip
    mlb_team = parts[1].strip

    match = name_and_positions.match(/^(.+?)\s+([\w,]+)$/)
    return [nil, nil, nil] unless match

    player_name = match[1].strip
    positions_raw = match[2].strip

    positions = positions_raw.split(',').map(&:strip).map do |pos|
      case pos.upcase
      when "U" then "UTIL"
      when "DH" then nil
      else pos.upcase
      end
    end.compact.uniq.join(',')

    return [nil, nil, nil] if positions.empty?

    [player_name, positions, mlb_team]
  end

  # Format: Avail, Player, AB, R, H, 1B, 2B, 3B, HR, RBI, BB, K, SB, CS, AVG, OBP, SLG, Rank
  def parse_hitter_stats(row)
    {
      "at_bats" => row[2].to_i,
      "runs" => row[3].to_i,
      "hits" => row[4].to_i,
      "singles" => row[5].to_i,
      "doubles" => row[6].to_i,
      "triples" => row[7].to_i,
      "home_runs" => row[8].to_i,
      "rbi" => row[9].to_i,
      "batter_walks" => row[10].to_i,
      "batter_strikeouts" => row[11].to_i,
      "stolen_bases" => row[12].to_i,
      "caught_stealing" => row[13].to_i,
      "batting_average" => row[14].to_f,
      "obp" => row[15].to_f,
      "slg" => row[16].to_f
    }
  end

  # Format: Avail, Player, INNs, APP, GS, QS, CG, W, L, S, BS, HD, K, BB, H, ERA, WHIP, Rank
  def parse_pitcher_stats(row)
    {
      "innings_pitched" => row[2].to_f,
      "appearances" => row[3].to_i,
      "games_started" => row[4].to_i,
      "quality_starts" => row[5].to_i,
      "complete_games" => row[6].to_i,
      "wins" => row[7].to_i,
      "losses" => row[8].to_i,
      "saves" => row[9].to_i,
      "blown_saves" => row[10].to_i,
      "holds" => row[11].to_i,
      "strikeouts" => row[12].to_i,
      "walks" => row[13].to_i,
      "hits_allowed" => row[14].to_i,
      "era" => row[15].to_f,
      "whip" => row[16].to_f
    }
  end
end
