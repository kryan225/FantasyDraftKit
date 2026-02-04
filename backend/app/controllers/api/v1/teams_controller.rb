class Api::V1::TeamsController < ApplicationController
  before_action :set_team, only: [:show, :category_analysis]
  before_action :set_league, only: [:index, :create]

  # GET /api/v1/leagues/:league_id/teams
  def index
    @teams = @league.teams
    render json: @teams
  end

  # GET /api/v1/teams/:id
  def show
    render json: @team, include: { draft_picks: { include: :player } }
  end

  # POST /api/v1/leagues/:league_id/teams
  def create
    @team = @league.teams.new(team_params)

    if @team.save
      render json: @team, status: :created
    else
      render json: { errors: @team.errors.full_messages }, status: :unprocessable_entity
    end
  end

  # GET /api/v1/teams/:id/category_analysis
  def category_analysis
    # Placeholder for category analysis logic
    # This would aggregate player stats across 5x5 roto categories
    # and show team strengths/weaknesses

    draft_picks = @team.draft_picks.includes(:player)
    players = draft_picks.map(&:player)

    # TODO: Implement actual category aggregation from player projections
    analysis = {
      team_id: @team.id,
      team_name: @team.name,
      categories: {
        batting: {
          runs: 0,
          home_runs: 0,
          rbi: 0,
          stolen_bases: 0,
          batting_average: 0.000
        },
        pitching: {
          wins: 0,
          saves: 0,
          strikeouts: 0,
          era: 0.00,
          whip: 0.00
        }
      },
      player_count: players.count
    }

    render json: analysis
  end

  private

  def set_team
    @team = Team.find(params[:id])
  rescue ActiveRecord::RecordNotFound
    render json: { error: "Team not found" }, status: :not_found
  end

  def set_league
    @league = League.find(params[:league_id])
  rescue ActiveRecord::RecordNotFound
    render json: { error: "League not found" }, status: :not_found
  end

  def team_params
    params.require(:team).permit(:name, :budget_remaining)
  end
end
