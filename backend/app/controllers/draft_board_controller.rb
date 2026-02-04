class DraftBoardController < ApplicationController
  def show
    @league = League.find(params[:league_id])
    @teams = @league.teams.order(:name)
    @draft_picks = @league.draft_picks.includes(:team, :player).order(:pick_number)
    @available_players = Player.available.order(calculated_value: :desc).limit(50)
  end
end
