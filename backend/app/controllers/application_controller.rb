class ApplicationController < ActionController::Base
  # Skip CSRF protection for API endpoints only
  protect_from_forgery with: :exception, unless: -> { request.format.json? }

  before_action :load_teams_for_modal
  before_action :set_current_league_for_view

  # Make current_league available as a helper method in views
  helper_method :current_league

  private

  def load_teams_for_modal
    # Load teams for the edit player modal if a league exists
    league = current_league_for_teams
    if league
      @teams_for_modal = league.teams.order(:name)
    else
      @teams_for_modal = []
    end
  end

  def set_current_league_for_view
    # Make sure @current_league is set for the view
    @current_league = current_league if respond_to?(:current_league)
  end

  def current_league_for_teams
    # Try to get current_league if available, otherwise fall back to first league
    if respond_to?(:current_league)
      current_league
    elsif League.any?
      League.first
    end
  end

  # Stub method for controllers that don't include LeagueResolvable
  def current_league
    nil
  end
end
