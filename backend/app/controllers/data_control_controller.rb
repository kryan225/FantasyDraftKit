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
      merged_count = 0
      merged_names = []
      csv_type = nil # :hitter or :pitcher, auto-detected from header row

      CSV.foreach(file.path, headers: false, encoding: 'UTF-8') do |row|
        first_cell = row[0]&.strip

        # Skip title rows (e.g. "All Players - Batters")
        next if first_cell&.include?("All Players")

        # Detect CSV type from header row
        if first_cell == "Avail"
          csv_type = row[2]&.strip == "AB" ? :hitter : :pitcher
          next
        end

        next if row[1].nil? || row[1].strip.empty?

        player_name, positions, mlb_team = parse_player_info(row[1])
        next unless player_name && positions && mlb_team

        # Parse stats based on CSV type (not player positions)
        projections = if csv_type == :pitcher
                        parse_pitcher_stats(row)
                      else
                        parse_hitter_stats(row)
                      end

        # Check if player already exists — merge projections for two-way players
        existing_player = Player.find_by(name: player_name, mlb_team: mlb_team)
        if existing_player
          merged_projections = (existing_player.projections || {}).merge(projections)
          merged_positions = (existing_player.positions.to_s.split(',') | positions.split(',')).join(',')
          existing_player.update!(projections: merged_projections, positions: merged_positions)
          merged_names << player_name
          Rails.logger.info "  MERGED: #{player_name} (#{mlb_team})"
          merged_count += 1
          next
        end

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

      message = "Successfully imported #{imported_count} new players."
      message += " Merged #{merged_count} existing players: #{merged_names.join(', ')}." if merged_names.any?
      redirect_to league_data_control_path(@league), notice: message
    rescue CSV::MalformedCSVError => e
      redirect_to league_data_control_path(@league), alert: "Error parsing CSV file: #{e.message}"
    rescue StandardError => e
      redirect_to league_data_control_path(@league), alert: "Error importing players: #{e.message}"
    end
  end

  def import_fangraphs
    @league = current_league
    return redirect_to data_control_path(league_id: @league&.id), alert: "League not found" unless @league

    unless params[:file].present?
      return redirect_to league_data_control_path(@league), alert: "Please select a FanGraphs CSV file to import"
    end

    file = params[:file]

    begin
      imported_count = 0
      merged_count = 0
      merged_names = []

      raw_headers = File.open(file.path, &:readline).chomp.split(",").map { |h| h.delete("\xEF\xBB\xBF").strip }
      csv_type = if raw_headers.include?("PA")
                   :hitter
                 elsif raw_headers.include?("IP")
                   :pitcher
                 else
                   raise "Unable to detect CSV type: header must contain PA (batting) or IP (pitching)"
                 end

      CSV.foreach(file.path, headers: true, encoding: 'bom|utf-8') do |row|
        # Clean BOM from header keys
        clean_row = {}
        row.each { |k, v| clean_row[k&.delete("\xEF\xBB\xBF")&.strip] = v }

        player_name = clean_row["NameASCII"].presence || clean_row["Name"]
        next if player_name.blank?
        player_name = player_name.strip.delete('"')

        mlb_team = clean_row["Team"]&.strip&.delete('"')
        next if mlb_team.blank?

        projections = if csv_type == :hitter
                        parse_fangraphs_hitter_stats(clean_row)
                      else
                        parse_fangraphs_pitcher_stats(clean_row)
                      end

        existing_player = Player.find_by(name: player_name, mlb_team: mlb_team)
        if existing_player
          merged_projections = (existing_player.projections || {}).merge(projections)
          existing_player.update!(projections: merged_projections)
          merged_names << player_name
          merged_count += 1
          next
        end

        default_positions = csv_type == :hitter ? "UTIL" : "SP"

        Player.create!(
          name: player_name,
          positions: default_positions,
          mlb_team: mlb_team,
          projections: projections,
          calculated_value: 0,
          is_drafted: false
        )

        imported_count += 1
      end

      message = "Successfully imported #{imported_count} new players from FanGraphs."
      message += " Merged projections for #{merged_count} existing players: #{merged_names.join(', ')}." if merged_names.any?
      redirect_to league_data_control_path(@league), notice: message
    rescue CSV::MalformedCSVError => e
      redirect_to league_data_control_path(@league), alert: "Error parsing FanGraphs CSV: #{e.message}"
    rescue StandardError => e
      redirect_to league_data_control_path(@league), alert: "Error importing FanGraphs data: #{e.message}"
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

  def save_snapshot
    @league = current_league
    snapshot_path = Rails.root.join("db", "snapshots", "baseline.sql")

    db_config = ActiveRecord::Base.connection_db_config.configuration_hash
    db_name = db_config[:database]
    host = db_config[:host] || "localhost"
    port = db_config[:port] || 5434
    username = db_config[:username]

    result = system(
      { "PGPASSWORD" => db_config[:password].to_s },
      "pg_dump", "-h", host.to_s, "-p", port.to_s, "-U", username.to_s,
      "--clean", "--if-exists", db_name.to_s,
      out: snapshot_path.to_s
    )

    if result
      redirect_to league_data_control_path(@league), notice: "Snapshot saved successfully."
    else
      redirect_to league_data_control_path(@league), alert: "Failed to save snapshot."
    end
  end

  def restore_snapshot
    @league = current_league
    snapshot_path = Rails.root.join("db", "snapshots", "baseline.sql")

    unless File.exist?(snapshot_path)
      return redirect_to league_data_control_path(@league), alert: "No snapshot file found."
    end

    db_config = ActiveRecord::Base.connection_db_config.configuration_hash
    db_name = db_config[:database]
    host = db_config[:host] || "localhost"
    port = db_config[:port] || 5434
    username = db_config[:username]

    # Disconnect all active connections before restoring
    ActiveRecord::Base.connection_pool.disconnect!

    result = system(
      { "PGPASSWORD" => db_config[:password].to_s },
      "psql", "-h", host.to_s, "-p", port.to_s, "-U", username.to_s, "-d", db_name.to_s,
      "-f", snapshot_path.to_s,
      out: File::NULL, err: File::NULL
    )

    # Reconnect
    ActiveRecord::Base.establish_connection

    if result
      redirect_to league_data_control_path(@league), notice: "Database restored from snapshot successfully."
    else
      redirect_to league_data_control_path(@league), alert: "Failed to restore database from snapshot."
    end
  end

  def recalculate_values
    @league = current_league
    return redirect_to data_control_path(league_id: @league&.id), alert: "League not found" unless @league

    service = ValueCalculatorService.new(@league)
    result = service.call

    if result[:error]
      redirect_to league_data_control_path(@league), alert: "Failed: #{result[:error]}"
    else
      redirect_to league_data_control_path(@league),
                  notice: "Recalculated #{result[:count]} players. " \
                          "Range: $#{result[:min_value].round}-$#{result[:max_value].round}, " \
                          "Avg: $#{result[:avg_value].round}, " \
                          "Time: #{result[:elapsed_time]}s"
    end
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

  # Parse hitter statistics from CSV row
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

  # Parse pitcher statistics from CSV row
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

  # Parse FanGraphs ATC batting projection stats
  def parse_fangraphs_hitter_stats(row)
    {
      # Core stats mapped to existing projection keys
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
      # FanGraphs-specific advanced stats
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

  # Parse FanGraphs ATC pitching projection stats
  def parse_fangraphs_pitcher_stats(row)
    {
      # Core stats mapped to existing projection keys
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
      # FanGraphs-specific advanced stats
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
