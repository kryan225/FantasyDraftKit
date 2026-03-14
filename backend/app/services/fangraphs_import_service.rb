# frozen_string_literal: true

require 'csv'

# FangraphsImportService
#
# Imports player projections from FanGraphs ATC projection CSV exports.
# Auto-detects hitter vs pitcher from header row (PA = hitter, IP = pitcher).
# Merges projections for existing players matched by name + team.
#
# Usage:
#   result = FangraphsImportService.new(file_path).call
#   # => { merged: 230, merged_names: ["Aaron Judge", ...], skipped: 15 }
#
class FangraphsImportService
  # FanGraphs uses 3-letter abbreviations; Yahoo uses shorter ones.
  TEAM_ABBREVIATION_MAP = {
    "SDP" => "SD",
    "SFG" => "SF",
    "WSN" => "WAS",
    "CHW" => "CWS",
    "KCR" => "KC",
    "TBR" => "TB"
  }.freeze

  attr_reader :file_path

  def initialize(file_path)
    @file_path = file_path
  end

  def call
    merged_count = 0
    merged_names = []
    skipped_count = 0

    csv_type = detect_csv_type

    CSV.foreach(file_path, headers: true, encoding: 'bom|utf-8') do |row|
      clean_row = clean_bom_headers(row)

      player_name = clean_row["NameASCII"].presence || clean_row["Name"]
      next if player_name.blank?
      player_name = player_name.strip.delete('"')

      mlb_team = clean_row["Team"]&.strip&.delete('"')
      next if mlb_team.blank?
      mlb_team = TEAM_ABBREVIATION_MAP.fetch(mlb_team, mlb_team)

      existing_player = Player.find_by(name: player_name, mlb_team: mlb_team)
      unless existing_player
        skipped_count += 1
        next
      end

      projections = csv_type == :hitter ? parse_hitter_stats(clean_row) : parse_pitcher_stats(clean_row)
      merged_projections = (existing_player.projections || {}).merge(projections)
      existing_player.update!(projections: merged_projections)
      merged_names << player_name
      merged_count += 1
    end

    { merged: merged_count, merged_names: merged_names, skipped: skipped_count }
  end

  private

  def detect_csv_type
    raw_headers = File.open(file_path, &:readline).chomp.split(",").map { |h| h.delete("\xEF\xBB\xBF").strip }
    if raw_headers.include?("PA")
      :hitter
    elsif raw_headers.include?("IP")
      :pitcher
    else
      raise "Unable to detect CSV type: header must contain PA (batting) or IP (pitching)"
    end
  end

  def clean_bom_headers(row)
    clean = {}
    row.each { |k, v| clean[k&.delete("\xEF\xBB\xBF")&.strip] = v }
    clean
  end

  def parse_hitter_stats(row)
    {
      "at_bats" => row["AB"].to_f,
      "runs" => row["R"].to_f,
      "hits" => row["H"].to_f,
      "singles" => row["1B"].to_f,
      "doubles" => row["2B"].to_f,
      "triples" => row["3B"].to_f,
      "home_runs" => row["HR"].to_f,
      "rbi" => row["RBI"].to_f,
      "batter_walks" => row["BB"].to_f,
      "batter_strikeouts" => row["SO"].to_f,
      "stolen_bases" => row["SB"].to_f,
      "caught_stealing" => row["CS"].to_f,
      "batting_average" => row["AVG"].to_f,
      "obp" => row["OBP"].to_f,
      "slg" => row["SLG"].to_f,
      "fpts" => row["FPTS"].to_f,
      "adp" => row["ADP"].to_f,
      "woba" => row["wOBA"].to_f,
      "wrc_plus" => row["wRC+"].to_f,
      "war" => row["WAR"].to_f,
      "k_pct" => row["K%"].to_f,
      "bb_pct" => row["BB%"].to_f,
      "inter_sd" => row["InterSD"].to_f,
      "intra_sd" => row["IntraSD"].to_f,
      "vol" => row["Vol"].to_f,
      "skew" => row["Skew"].to_f,
      "fangraphs_id" => row["PlayerId"]&.strip
    }
  end

  def parse_pitcher_stats(row)
    {
      "innings_pitched" => row["IP"].to_f,
      "appearances" => row["G"].to_f,
      "games_started" => row["GS"].to_f,
      "quality_starts" => row["QS"].to_f,
      "wins" => row["W"].to_f,
      "losses" => row["L"].to_f,
      "saves" => row["SV"].to_f,
      "blown_saves" => row["BS"].to_f,
      "holds" => row["HLD"].to_f,
      "strikeouts" => row["SO"].to_f,
      "walks" => row["BB"].to_f,
      "hits_allowed" => row["H"].to_f,
      "era" => row["ERA"].to_f,
      "whip" => row["WHIP"].to_f,
      "fpts" => row["FPTS"].to_f,
      "adp" => row["ADP"].to_f,
      "fip" => row["FIP"].to_f,
      "war" => row["WAR"].to_f,
      "k_pct" => row["K%"].to_f,
      "bb_pct" => row["BB%"].to_f,
      "inter_sd" => row["InterSD"].to_f,
      "intra_sd" => row["IntraSD"].to_f,
      "vol" => row["Vol"].to_f,
      "skew" => row["Skew"].to_f,
      "fangraphs_id" => row["PlayerId"]&.strip
    }
  end
end
