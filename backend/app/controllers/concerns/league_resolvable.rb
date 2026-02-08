# frozen_string_literal: true

# LeagueResolvable - A concern for controllers that need to resolve a league context
#
# This module provides intelligent league resolution:
# - Uses params[:league_id] if explicitly provided
# - Auto-selects the only league if there's exactly one
# - Redirects with an error if multiple leagues exist and no ID is specified
#
# This follows the Single Responsibility Principle by encapsulating league
# resolution logic in one place, and DRY by making it reusable across controllers.
module LeagueResolvable
  extend ActiveSupport::Concern

  private

  # Resolves and returns the current league based on params or database state
  #
  # @return [League, nil] The resolved league, or nil if redirect occurred
  # @raise [ActiveRecord::RecordNotFound] if league_id doesn't exist
  def current_league
    return @current_league if defined?(@current_league)

    @current_league = resolve_league
  end

  # Core logic for league resolution
  #
  # @return [League, nil] The resolved league, or nil if redirect occurred
  def resolve_league
    # Case 1: Explicit league_id provided in params
    if params[:league_id].present?
      return League.find(params[:league_id])
    end

    # Case 2: Only one league exists - use it automatically (KISS principle)
    league_count = League.count
    if league_count == 1
      return League.first
    end

    # Case 3: Multiple leagues exist - require user to select one
    if league_count > 1
      redirect_to leagues_path, alert: "Please select a league first."
      return nil
    end

    # Case 4: No leagues exist
    redirect_to leagues_path, alert: "No leagues found. Please create a league first."
    nil
  end

  # Helper to ensure a league is resolved before proceeding
  # Use as a before_action in controllers
  #
  # Note: This method checks if current_league returned a value. If current_league
  # returned nil, it means a redirect already occurred in resolve_league, so we
  # don't need to perform another redirect (which would cause DoubleRenderError).
  def ensure_league
    # current_league handles redirects internally; we just need to check if it returned nil
    current_league.present?
  end
end
