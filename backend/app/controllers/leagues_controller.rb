class LeaguesController < ApplicationController
  before_action :set_league, only: [:show, :settings, :update]

  def index
    @leagues = League.all
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
    @league = League.new
  end

  def create
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
end
