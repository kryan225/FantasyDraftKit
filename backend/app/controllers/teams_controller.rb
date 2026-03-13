require "csv"

class TeamsController < ApplicationController
  include LeagueResolvable

  before_action :ensure_league, only: [:index, :export_rosters]

  def index
    @teams = current_league.teams.order(:name)
  end

  def show
    @team = Team.includes(draft_picks: :player).find(params[:id])
    @league = @team.league
  end

  def export_rosters
    league = current_league
    teams = league.teams.includes(draft_picks: :player).order(:name)

    csv_data = CSV.generate do |csv|
      csv << ["Team", "Player", "Position", "Price", "Topped"]

      teams.each do |team|
        picks = team.draft_picks.sort_by(&:pick_number)
        picks.each do |pick|
          csv << [
            team.name,
            pick.player.name,
            pick.player.positions,
            pick.price,
            pick.is_topped ? "Yes" : "No"
          ]
        end
      end
    end

    send_data csv_data,
              filename: "#{league.name.parameterize}-rosters-#{Date.today}.csv",
              type: "text/csv",
              disposition: "attachment"
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
