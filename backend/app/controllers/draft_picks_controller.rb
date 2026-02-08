# frozen_string_literal: true

# DraftPicksController - Web UI controller for draft pick operations with Turbo Streams
#
# This controller handles draft pick creation and deletion for the web UI,
# responding with Turbo Stream updates instead of full page reloads.
class DraftPicksController < ApplicationController
  include LeagueResolvable

  before_action :ensure_league, except: [:update]
  before_action :set_draft_pick, only: [:update, :destroy]

  # POST /draft_picks
  # Creates a new draft pick and responds with Turbo Streams to update the UI
  def create
    @league = current_league
    return unless @league

    @draft_pick = @league.draft_picks.new(draft_pick_params)

    # Auto-assign pick number if not provided
    if @draft_pick.pick_number.nil?
      @draft_pick.pick_number = @league.draft_picks.maximum(:pick_number).to_i + 1
    end

    if @draft_pick.save
      # Load data for Turbo Stream updates
      @teams = @league.teams.order(:name)
      @draft_picks = @league.draft_picks.includes(:team, :player).order(:pick_number)
      @interested_available_players = Player.available.interested.order(calculated_value: :desc)

      respond_to do |format|
        format.turbo_stream
        format.html { redirect_to draft_board_path, notice: "Player drafted successfully!" }
      end
    else
      respond_to do |format|
        format.turbo_stream do
          render turbo_stream: turbo_stream.update(
            "draft-error",
            partial: "draft_picks/error",
            locals: { errors: @draft_pick.errors.full_messages }
          )
        end
        format.html { redirect_to draft_board_path, alert: @draft_pick.errors.full_messages.join(", ") }
      end
    end
  end

  # PATCH /draft_picks/:id
  # Updates a draft pick's position (for roster moves)
  def update
    if @draft_pick.update(draft_pick_params)
      @team = @draft_pick.team
      @league = @team.league

      # Reload roster data
      roster_config = @league.roster_config || {}
      @picks_by_position = @team.draft_picks.group_by(&:drafted_position)
      @position_groups = [
        { name: "Batters", positions: ["C", "1B", "2B", "3B", "SS", "MI", "CI", "OF"] },
        { name: "Utility", positions: ["UTIL"] },
        { name: "Pitchers", positions: ["SP", "RP"] },
        { name: "Bench", positions: ["BENCH"] }
      ]
      @roster_config = roster_config

      respond_to do |format|
        format.turbo_stream
        format.html { redirect_to team_path(@team), notice: "Player moved successfully!" }
      end
    else
      respond_to do |format|
        format.turbo_stream do
          render turbo_stream: turbo_stream.update(
            "roster-error",
            partial: "shared/error",
            locals: { errors: @draft_pick.errors.full_messages }
          )
        end
        format.html { redirect_to team_path(@team), alert: @draft_pick.errors.full_messages.join(", ") }
      end
    end
  end

  # DELETE /draft_picks/:id
  # Undoes a draft pick and responds with Turbo Streams to update the UI
  def destroy
    @league = @draft_pick.league
    @draft_pick.destroy

    # Load data for Turbo Stream updates
    @teams = @league.teams.order(:name)
    @draft_picks = @league.draft_picks.includes(:team, :player).order(:pick_number)
    @interested_available_players = Player.available.interested.order(calculated_value: :desc)

    respond_to do |format|
      format.turbo_stream
      format.html { redirect_to draft_board_path, notice: "Draft pick undone successfully!" }
    end
  end

  private

  def set_draft_pick
    @draft_pick = DraftPick.find(params[:id])
  rescue ActiveRecord::RecordNotFound
    redirect_to draft_board_path, alert: "Draft pick not found"
  end

  def draft_pick_params
    params.require(:draft_pick).permit(:team_id, :player_id, :price, :is_keeper, :pick_number, :drafted_position)
  end
end
