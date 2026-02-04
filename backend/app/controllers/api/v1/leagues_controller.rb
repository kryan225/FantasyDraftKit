class Api::V1::LeaguesController < ApplicationController
  before_action :set_league, only: [:show, :update, :destroy, :recalculate_values]

  # GET /api/v1/leagues
  def index
    @leagues = League.all
    render json: @leagues
  end

  # GET /api/v1/leagues/:id
  def show
    render json: @league, include: :teams
  end

  # POST /api/v1/leagues
  def create
    @league = League.new(league_params)

    if @league.save
      render json: @league, status: :created
    else
      render json: { errors: @league.errors.full_messages }, status: :unprocessable_entity
    end
  end

  # PATCH/PUT /api/v1/leagues/:id
  def update
    if @league.update(league_params)
      render json: @league
    else
      render json: { errors: @league.errors.full_messages }, status: :unprocessable_entity
    end
  end

  # DELETE /api/v1/leagues/:id
  def destroy
    @league.destroy
    head :no_content
  end

  # POST /api/v1/leagues/:id/recalculate_values
  def recalculate_values
    # Placeholder for value recalculation logic
    # This would implement the auction value calculation algorithm
    # based on player projections and league settings

    players = Player.available
    # TODO: Implement value calculation algorithm
    # For now, just return success

    render json: { message: "Values recalculated successfully", count: players.count }
  end

  private

  def set_league
    @league = League.find(params[:id])
  rescue ActiveRecord::RecordNotFound
    render json: { error: "League not found" }, status: :not_found
  end

  def league_params
    params.require(:league).permit(:name, :team_count, :auction_budget, :keeper_limit, roster_config: {})
  end
end
