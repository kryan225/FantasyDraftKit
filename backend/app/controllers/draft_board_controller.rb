class DraftBoardController < ApplicationController
  include LeagueResolvable

  before_action :ensure_league

  def show
    @league = current_league
    return unless @league # ensure_league may have redirected

    @teams = @league.teams.order(:name)
    @draft_picks = @league.draft_picks.includes(:team, :player).order(:pick_number)
    @available_players = Player.available.order(calculated_value: :desc).limit(50)
  end
end
