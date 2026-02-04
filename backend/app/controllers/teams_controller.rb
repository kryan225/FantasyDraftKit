class TeamsController < ApplicationController
  def show
    @team = Team.includes(draft_picks: :player).find(params[:id])
    @league = @team.league
  end
end
