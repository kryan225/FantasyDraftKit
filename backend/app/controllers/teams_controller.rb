class TeamsController < ApplicationController
  include LeagueResolvable

  before_action :ensure_league, only: [:index]

  def index
    @teams = current_league.teams.order(:name)
  end

  def show
    @team = Team.includes(draft_picks: :player).find(params[:id])
    @league = @team.league
  end

  private

  # Override for show action to get league from team
  def current_league
    if action_name == 'show' && @team
      @team.league
    else
      super
    end
  end
end
