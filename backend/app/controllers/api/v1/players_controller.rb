class Api::V1::PlayersController < ApplicationController
  # GET /api/v1/players
  def index
    @players = Player.all

    # Apply filters if provided
    @players = @players.where(is_drafted: params[:is_drafted]) if params[:is_drafted].present?
    @players = @players.by_position(params[:position]) if params[:position].present?
    @players = @players.where("name ILIKE ?", "%#{params[:search]}%") if params[:search].present?

    # Ordering
    order_by = params[:order_by] || "calculated_value"
    order_direction = params[:order_direction] || "desc"
    @players = @players.order("#{order_by} #{order_direction} NULLS LAST")

    render json: @players
  end

  # POST /api/v1/players/import
  def import
    unless params[:file].present?
      return render json: { error: "No file provided" }, status: :unprocessable_entity
    end

    begin
      # Parse CSV file
      require 'csv'
      file = params[:file]
      imported_count = 0
      errors = []

      CSV.foreach(file.path, headers: true) do |row|
        player = Player.new(
          name: row['name'] || row['Name'],
          positions: row['positions'] || row['Positions'],
          mlb_team: row['mlb_team'] || row['Team'],
          projections: parse_projections(row),
          calculated_value: row['calculated_value'] || row['Value'] || 0,
          is_drafted: false
        )

        if player.save
          imported_count += 1
        else
          errors << "Row #{row.line}: #{player.errors.full_messages.join(', ')}"
        end
      end

      render json: {
        message: "Import completed",
        imported: imported_count,
        errors: errors
      }, status: :created

    rescue CSV::MalformedCSVError => e
      render json: { error: "Invalid CSV format: #{e.message}" }, status: :unprocessable_entity
    rescue StandardError => e
      render json: { error: "Import failed: #{e.message}" }, status: :internal_server_error
    end
  end

  # POST /api/v1/leagues/:id/recalculate_values (handled in LeaguesController)

  private

  def parse_projections(row)
    # Extract projection columns from CSV
    # This is a flexible parser that handles various CSV formats
    projections = {}

    # Batting stats
    projections['runs'] = row['R'] || row['runs'] if row['R'] || row['runs']
    projections['home_runs'] = row['HR'] || row['home_runs'] if row['HR'] || row['home_runs']
    projections['rbi'] = row['RBI'] || row['rbi'] if row['RBI'] || row['rbi']
    projections['stolen_bases'] = row['SB'] || row['stolen_bases'] if row['SB'] || row['stolen_bases']
    projections['batting_average'] = row['AVG'] || row['batting_average'] if row['AVG'] || row['batting_average']

    # Pitching stats
    projections['wins'] = row['W'] || row['wins'] if row['W'] || row['wins']
    projections['saves'] = row['SV'] || row['saves'] if row['SV'] || row['saves']
    projections['strikeouts'] = row['K'] || row['strikeouts'] if row['K'] || row['strikeouts']
    projections['era'] = row['ERA'] || row['era'] if row['ERA'] || row['era']
    projections['whip'] = row['WHIP'] || row['whip'] if row['WHIP'] || row['whip']

    projections.compact
  end
end
