require "csv"

class DraftBoardController < ApplicationController
  include LeagueResolvable

  before_action :ensure_league

  def show
    @league = current_league
    return unless @league # ensure_league may have redirected

    @teams = @league.teams.includes(:draft_picks).order(:name)
    @draft_picks = @league.draft_picks.includes(:team, :player).order(pick_number: :desc)
    @players = PlayerFilterService.new(params).call
  end

  def history
    @league = current_league
    return unless @league # ensure_league may have redirected

    @draft_picks = @league.draft_picks.includes(:team, :player).order(pick_number: :desc)
  end

  def worksheet
    @league = current_league
    return unless @league

    @teams = @league.teams.includes(draft_picks: :player).order(:name)
    @roster_config = @league.roster_config || {}

    # Define position display order matching the spreadsheet layout
    @position_slots = []
    %w[C 1B CI 3B 2B MI SS OF UTIL SP RP BENCH].each do |pos|
      count = @roster_config[pos].to_i
      count.times { @position_slots << pos }
    end

    # Build a lookup: for each team, group picks by drafted_position
    @team_rosters = {}
    @teams.each do |team|
      picks_by_pos = team.draft_picks.group_by(&:drafted_position)
      @team_rosters[team.id] = picks_by_pos
    end
  end

  def export_history
    @league = current_league
    return unless @league

    picks = @league.draft_picks.includes(:team, :player).order(:pick_number)

    csv_data = CSV.generate do |csv|
      csv << ["Pick #", "Player", "Team", "Position", "Price", "Keeper", "Topped"]

      picks.each do |pick|
        csv << [
          pick.is_keeper ? 0 : pick.pick_number,
          pick.player.name,
          pick.team.name,
          pick.player.positions,
          pick.price,
          pick.is_keeper ? "Yes" : "No",
          pick.is_topped ? "Yes" : "No"
        ]
      end
    end

    send_data csv_data,
              filename: "#{@league.name.parameterize}-draft-history-#{Date.today}.csv",
              type: "text/csv",
              disposition: "attachment"
  end
end
