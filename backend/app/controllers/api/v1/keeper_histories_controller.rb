class Api::V1::KeeperHistoriesController < Api::V1::BaseController
  before_action :set_league, only: [:index, :import_keepers, :check_keeper_eligibility]

  # GET /api/v1/leagues/:league_id/keeper_history
  def index
    @keeper_histories = KeeperHistory
      .joins(:team)
      .where(teams: { league_id: @league.id })
      .includes(:player, :team)
      .order(year: :desc)

    # Filter by year if provided
    @keeper_histories = @keeper_histories.for_year(params[:year]) if params[:year].present?

    render json: @keeper_histories, include: [:player, :team]
  end

  # POST /api/v1/leagues/:league_id/import_keepers
  def import_keepers
    unless params[:file].present?
      return render json: { error: "No file provided" }, status: :unprocessable_entity
    end

    begin
      require 'csv'
      file = params[:file]
      imported_count = 0
      errors = []

      CSV.foreach(file.path, headers: true) do |row|
        # Find team by name
        team = @league.teams.find_by(name: row['team'] || row['Team'])
        unless team
          errors << "Row #{row.line}: Team '#{row['team'] || row['Team']}' not found"
          next
        end

        # Find or create player
        player = Player.find_or_create_by(name: row['player'] || row['Player']) do |p|
          p.positions = row['positions'] || row['Positions'] || 'UNKNOWN'
          p.mlb_team = row['mlb_team'] || row['Team'] || 'UNKNOWN'
          p.is_drafted = false
        end

        keeper = KeeperHistory.new(
          player: player,
          team: team,
          year: (row['year'] || row['Year'] || Time.current.year - 1).to_i,
          price: (row['price'] || row['Price'] || 0).to_i
        )

        if keeper.save
          imported_count += 1
        else
          errors << "Row #{row.line}: #{keeper.errors.full_messages.join(', ')}"
        end
      end

      render json: {
        message: "Keeper import completed",
        imported: imported_count,
        errors: errors
      }, status: :created

    rescue CSV::MalformedCSVError => e
      render json: { error: "Invalid CSV format: #{e.message}" }, status: :unprocessable_entity
    rescue StandardError => e
      render json: { error: "Import failed: #{e.message}" }, status: :internal_server_error
    end
  end

  # GET /api/v1/leagues/:league_id/check_keeper_eligibility
  def check_keeper_eligibility
    player_id = params[:player_id]
    team_id = params[:team_id]

    unless player_id && team_id
      return render json: { error: "player_id and team_id are required" }, status: :unprocessable_entity
    end

    # Get keeper history for this player and team
    keeper_history = KeeperHistory
      .where(player_id: player_id, team_id: team_id)
      .order(year: :desc)
      .limit(3)

    years_kept = keeper_history.count
    keeper_limit = @league.keeper_limit || 3

    eligible = years_kept < keeper_limit

    render json: {
      eligible: eligible,
      years_kept: years_kept,
      keeper_limit: keeper_limit,
      history: keeper_history.as_json(include: :player),
      message: eligible ? "Player is eligible to be kept" : "Player has exceeded keeper limit"
    }
  end

  private

  def set_league
    @league = League.find(params[:league_id])
  rescue ActiveRecord::RecordNotFound
    render json: { error: "League not found" }, status: :not_found
  end
end
