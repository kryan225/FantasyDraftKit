class DraftBoardController < ApplicationController
  include LeagueResolvable

  before_action :ensure_league

  def show
    @league = current_league
    return unless @league # ensure_league may have redirected

    @teams = @league.teams.order(:name)
    @draft_picks = @league.draft_picks.includes(:team, :player).order(pick_number: :desc)
    @interested_available_players = Player.available.interested.order(calculated_value: :desc)

    @players = PlayerFilterService.new(params).call
  end

  def history
    @league = current_league
    return unless @league # ensure_league may have redirected

    @draft_picks = @league.draft_picks.includes(:team, :player).order(pick_number: :desc)
  end
end
