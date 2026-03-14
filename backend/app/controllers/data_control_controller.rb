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

    begin
      result = YahooImportService.new(params[:file].path).call

      message = "Successfully imported #{result[:imported]} new players."
      if result[:merged_names].any?
        message += " Merged #{result[:merged]} existing players: #{result[:merged_names].join(', ')}."
      end
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

    begin
      result = FangraphsImportService.new(params[:file].path).call

      message = "Successfully imported #{result[:imported]} new players from FanGraphs."
      if result[:merged_names].any?
        message += " Merged projections for #{result[:merged]} existing players: #{result[:merged_names].join(', ')}."
      end
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

end
