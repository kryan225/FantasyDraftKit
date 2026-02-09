class DraftBoardController < ApplicationController
  include LeagueResolvable

  before_action :ensure_league

  def show
    @league = current_league
    return unless @league # ensure_league may have redirected

    @teams = @league.teams.order(:name)
    @draft_picks = @league.draft_picks.includes(:team, :player).order(pick_number: :desc)
    @interested_available_players = Player.available.interested.order(calculated_value: :desc)

    # Player database with filters
    @players = Player.all

    # Apply filters
    if params[:position].present?
      @players = @players.by_position(params[:position])
    end

    if params[:search].present?
      @players = @players.where("name ILIKE ?", "%#{params[:search]}%")
    end

    # Default to showing available players only (unless explicitly filtering)
    if params.key?(:drafted)
      # User has explicitly chosen a filter
      if params[:drafted] == "true"
        @players = @players.drafted
      elsif params[:drafted] == "false"
        @players = @players.available
      end
      # If params[:drafted] is "", show all players (no filter)
    else
      # No filter parameter provided, default to available only
      @players = @players.available
    end

    if params[:interested] == "true"
      @players = @players.interested
    end

    # Sort
    sort_column = params[:sort] || 'calculated_value'
    sort_direction = params[:direction] || 'desc'

    # Handle sorting by different columns
    case sort_column
    when 'name'
      @players = @players.order("name #{sort_direction}")
    when 'positions'
      @players = @players.order("positions #{sort_direction}")
    when 'mlb_team'
      @players = @players.order("mlb_team #{sort_direction}")
    when 'calculated_value'
      @players = @players.order("calculated_value #{sort_direction} NULLS LAST")
    when 'home_runs', 'runs', 'rbi', 'stolen_bases', 'batting_average', 'wins', 'saves', 'strikeouts', 'era', 'whip'
      # Sort by JSONB field
      @players = @players.order(Arel.sql("(projections->>'#{sort_column}')::float #{sort_direction} NULLS LAST"))
    else
      @players = @players.order(calculated_value: :desc)
    end
  end

  def history
    @league = current_league
    return unless @league # ensure_league may have redirected

    @draft_picks = @league.draft_picks.includes(:team, :player).order(pick_number: :desc)
  end
end
