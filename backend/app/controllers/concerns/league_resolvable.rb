# frozen_string_literal: true

# LeagueResolvable - A concern for controllers that need to resolve the league
#
# Single-league app: always resolves to League.first.
# If no league exists, redirects to league creation.
module LeagueResolvable
  extend ActiveSupport::Concern

  private

  def current_league
    return @current_league if defined?(@current_league)

    @current_league = League.first

    unless @current_league
      redirect_to new_league_path, alert: "No league found. Please create one first."
    end

    @current_league
  end

  def ensure_league
    current_league.present?
  end
end
