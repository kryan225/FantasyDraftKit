require 'csv'

class DataControlController < ApplicationController
  include LeagueResolvable

  before_action :ensure_league

  def show
    @league = current_league
    @player_count = Player.count
    @drafted_count = Player.where(is_drafted: true).count
    @available_count = Player.where(is_drafted: false).count
  end

  def import_players
    @league = current_league
    return redirect_to data_control_path(league_id: @league&.id), alert: "League not found" unless @league

    unless params[:file].present?
      return redirect_to league_data_control_path(@league), alert: "Please select a CSV file to import"
    end

    file = params[:file]

    begin
      imported_count = 0
      skipped_count = 0

      CSV.foreach(file.path, headers: false, encoding: 'UTF-8') do |row|
        # Skip header rows
        next if row[0]&.include?("All Players") || row[0] == "Avail"
        next if row[1].nil? || row[1].strip.empty?

        player_name, positions, mlb_team = parse_player_info(row[1])
        next unless player_name && positions && mlb_team

        # Check if player already exists
        existing_player = Player.find_by(name: player_name, mlb_team: mlb_team)
        if existing_player
          skipped_count += 1
          next
        end

        # Parse batting stats
        projections = {
          "at_bats" => row[2].to_i,
          "runs" => row[3].to_i,
          "hits" => row[4].to_i,
          "singles" => row[5].to_i,
          "doubles" => row[6].to_i,
          "triples" => row[7].to_i,
          "home_runs" => row[8].to_i,
          "rbi" => row[9].to_i,
          "walks" => row[10].to_i,
          "strikeouts" => row[11].to_i,
          "stolen_bases" => row[12].to_i,
          "caught_stealing" => row[13].to_i,
          "batting_average" => row[14].to_f,
          "obp" => row[15].to_f,
          "slg" => row[16].to_f
        }

        Player.create!(
          name: player_name,
          positions: positions,
          mlb_team: mlb_team,
          projections: projections,
          calculated_value: 0, # Will be calculated later
          is_drafted: false
        )

        imported_count += 1
      end

      redirect_to league_data_control_path(@league), notice: "Successfully imported #{imported_count} players. Skipped #{skipped_count} existing players."
    rescue CSV::MalformedCSVError => e
      redirect_to league_data_control_path(@league), alert: "Error parsing CSV file: #{e.message}"
    rescue StandardError => e
      redirect_to league_data_control_path(@league), alert: "Error importing players: #{e.message}"
    end
  end

  def undraft_all_players
    @league = current_league
    return redirect_to data_control_path(league_id: @league&.id), alert: "League not found" unless @league

    # Delete all draft picks for this league
    deleted_count = @league.draft_picks.count
    @league.draft_picks.destroy_all

    # Mark all players as undrafted
    Player.where(is_drafted: true).update_all(is_drafted: false)

    redirect_to league_data_control_path(@league), notice: "Successfully undrafted all players. Deleted #{deleted_count} draft picks."
  end

  def delete_all_players
    @league = current_league
    return redirect_to data_control_path(league_id: @league&.id), alert: "League not found" unless @league

    deleted_count = Player.count
    Player.destroy_all

    redirect_to league_data_control_path(@league), notice: "Successfully deleted #{deleted_count} players."
  end

  private

  def parse_player_info(player_string)
    # Format: "Aaron Judge OF,DH | NYY "
    # or: "Shohei Ohtani DH,U,SP | LAD "

    return [nil, nil, nil] unless player_string

    parts = player_string.split("|")
    return [nil, nil, nil] unless parts.length == 2

    name_and_positions = parts[0].strip
    mlb_team = parts[1].strip

    # Split name and positions - positions are after the last space
    # "Aaron Judge OF,DH" -> ["Aaron Judge", "OF,DH"]
    match = name_and_positions.match(/^(.+?)\s+([\w,]+)$/)
    return [nil, nil, nil] unless match

    player_name = match[1].strip
    positions_raw = match[2].strip

    # Clean up positions - convert U to UTIL, remove duplicates
    positions = positions_raw.split(',').map(&:strip).map do |pos|
      case pos.upcase
      when "U" then "UTIL"
      when "DH" then nil # DH is not a fantasy position
      else pos.upcase
      end
    end.compact.uniq.join(',')

    # If no positions remain, skip this player
    return [nil, nil, nil] if positions.empty?

    [player_name, positions, mlb_team]
  end
end
