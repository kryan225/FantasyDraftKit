class LeaguesController < ApplicationController
  before_action :set_league, only: [:show]

  def index
    @leagues = League.all
  end

  def show
    @teams = @league.teams.order(:name)
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
    params.require(:league).permit(:name, :team_count, :auction_budget, :keeper_limit)
  end
end
