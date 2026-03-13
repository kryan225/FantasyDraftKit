class PlayersController < ApplicationController
  include LeagueResolvable

  before_action :ensure_league
  before_action :set_player, only: [:edit, :update, :toggle_interested]

  def index
    @league = current_league
    @teams = @league.teams.order(:name)
    @players = PlayerFilterService.new(params).call
  end

  def edit
    # This action is not used with modal, but kept for RESTful completeness
  end

  def update
    # Handle team ownership change via draft/drop workflow
    if params[:player][:team_id].present? && params[:player][:team_id] != @player.team_id.to_s
      handle_team_change
    # Handle dropping player (setting team to nil/empty)
    elsif params[:player][:team_id].blank? && @player.team_id.present?
      handle_drop_player
    # Handle other player attribute updates
    else
      handle_regular_update
    end
  end

  def toggle_interested
    @player.cycle_interest!
    league_id = params[:league_id]

    respond_to do |format|
      format.turbo_stream do
        render turbo_stream: turbo_stream.replace(
          "player-row-#{@player.id}",
          partial: "draft_board/player_database_row",
          locals: { player: @player, league_id: league_id }
        )
      end
      format.json { render json: { interest_level: @player.interest_level } }
    end
  end

  private

  def set_player
    @player = Player.find(params[:id])
  rescue ActiveRecord::RecordNotFound
    redirect_to league_players_path(current_league), alert: "Player not found"
  end

  def player_params
    params.require(:player).permit(:name, :positions, :mlb_team, :calculated_value, :team_id, :price, :drafted_position, :notes)
  end

  # Handle team ownership change via proper draft/drop workflow
  def handle_team_change
    new_team_id = params[:player][:team_id]
    new_team = Team.find(new_team_id)
    price = params[:player][:price].to_i
    price = 1 if price <= 0 # Default minimum price
    drafted_position = params[:player][:drafted_position] || infer_position_from_player

    ActiveRecord::Base.transaction do
      # Step 1: Drop existing draft pick if player is currently owned
      if @player.team_id.present?
        existing_pick = DraftPick.find_by(player_id: @player.id, league_id: current_league.id)
        if existing_pick
          existing_pick.destroy!
        end
      end

      # Step 2: Draft player to new team
      draft_pick = DraftPick.new(
        league: current_league,
        team: new_team,
        player: @player,
        price: price,
        drafted_position: drafted_position,
        pick_number: current_league.draft_picks.maximum(:pick_number).to_i + 1
      )

      if draft_pick.save
        # Manually update player attributes after draft pick is created
        @player.update!(is_drafted: true, team_id: new_team_id)
        render_successful_update
      else
        # Validation failed, transaction will rollback
        render_team_change_error(draft_pick.errors.full_messages)
        raise ActiveRecord::Rollback
      end
    end
  rescue StandardError => e
    render_team_change_error([e.message])
  end

  # Handle dropping player (remove from team)
  def handle_drop_player
    ActiveRecord::Base.transaction do
      # Find and destroy the draft pick
      existing_pick = DraftPick.find_by(player_id: @player.id, league_id: current_league.id)

      if existing_pick
        existing_pick.destroy!
        # Manually update player attributes after draft pick is destroyed
        @player.update!(is_drafted: false, team_id: nil)
        render_successful_update
      else
        render_team_change_error(["No draft pick found for this player"])
        raise ActiveRecord::Rollback
      end
    end
  rescue StandardError => e
    render_team_change_error([e.message])
  end

  # Handle regular player attribute updates (not team-related)
  def handle_regular_update
    if @player.update(player_params.except(:team_id, :price, :drafted_position))
      render_successful_update
    else
      respond_to do |format|
        format.turbo_stream do
          render turbo_stream: turbo_stream.update(
            "edit-player-error",
            partial: "players/error",
            locals: { errors: @player.errors.full_messages }
          )
        end
        format.html { render :edit, status: :unprocessable_entity }
      end
    end
  end

  def render_successful_update
    respond_to do |format|
      format.turbo_stream do
        # Return empty turbo stream - JavaScript will handle the page reload
        render turbo_stream: turbo_stream.update("edit-player-error", "")
      end
      format.html { redirect_to league_players_path(current_league), notice: "Player updated successfully!" }
    end
  end

  def render_team_change_error(errors)
    respond_to do |format|
      format.turbo_stream do
        render turbo_stream: turbo_stream.update(
          "edit-player-error",
          partial: "players/error",
          locals: { errors: errors }
        )
      end
      format.html { redirect_to league_players_path(current_league), alert: errors.join(", ") }
    end
  end

  def infer_position_from_player
    # Parse player's positions and return the first one
    # Format is typically "1B/OF" or "SP"
    positions = @player.positions&.split(/[,\/]/)&.first
    positions&.strip || "UTIL"
  end
end
