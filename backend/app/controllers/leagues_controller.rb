class LeaguesController < ApplicationController
  include LeagueResolvable

  before_action :set_league, only: [:show, :settings, :update]

  def index
    # Single-league app: redirect straight to the league if one exists
    league = League.first
    if league
      redirect_to league_path(league)
    else
      redirect_to new_league_path
    end
  end

  def show
    @teams = @league.teams.order(:name)
  end

  def settings
    # Settings page for league configuration
  end

  def update
    # Convert roster_config values to integers
    if params[:league][:roster_config].present?
      params[:league][:roster_config] = params[:league][:roster_config].transform_values(&:to_i)
    end

    if @league.update(league_params)
      redirect_to settings_league_path(@league), notice: "League settings updated successfully!"
    else
      render :settings, status: :unprocessable_entity
    end
  end

  def new
    # Prevent creating a second league
    if League.any?
      redirect_to league_path(League.first), alert: "A league already exists. Only one league is supported."
      return
    end
    @league = League.new
  end

  def create
    if League.any?
      redirect_to league_path(League.first), alert: "A league already exists. Only one league is supported."
      return
    end

    @league = League.new(league_params)

    if @league.save
      redirect_to league_path(@league), notice: "League created successfully!"
    else
      render :new, status: :unprocessable_entity
    end
  end

  private

  def set_league
    @league = League.find(params[:id])
  end

  def league_params
    params.require(:league).permit(:name, :team_count, :auction_budget, :keeper_limit, roster_config: {})
  end

  def current_league
    @league || super
  end
end
