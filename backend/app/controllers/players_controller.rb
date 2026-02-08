class PlayersController < ApplicationController
  before_action :set_player, only: [:edit, :update]

  def index
    @players = Player.all

    # Apply filters
    if params[:position].present?
      @players = @players.by_position(params[:position])
    end

    if params[:search].present?
      @players = @players.where("name ILIKE ?", "%#{params[:search]}%")
    end

    if params[:drafted].present?
      @players = params[:drafted] == "true" ? @players.drafted : @players.available
    end

    # Sort
    @players = @players.order(calculated_value: :desc)
  end

  def edit
    # This action is not used with modal, but kept for RESTful completeness
  end

  def update
    if @player.update(player_params)
      respond_to do |format|
        format.turbo_stream do
          # Update player wherever they appear in the UI
          render turbo_stream: [
            # Update in draft picks table if drafted
            @player.is_drafted ? turbo_stream.replace("draft-pick-player-#{@player.id}",
              partial: "players/player_name",
              locals: { player: @player }) : nil,
            # Update in available players table if not drafted
            !@player.is_drafted ? turbo_stream.replace("available-player-#{@player.id}",
              partial: "draft_board/available_player_row",
              locals: { player: @player }) : nil,
            # Update in team roster if applicable
            turbo_stream.replace("player-#{@player.id}",
              partial: "players/player_name",
              locals: { player: @player })
          ].compact
        end
        format.html { redirect_to players_path, notice: "Player updated successfully!" }
      end
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

  private

  def set_player
    @player = Player.find(params[:id])
  rescue ActiveRecord::RecordNotFound
    redirect_to players_path, alert: "Player not found"
  end

  def player_params
    params.require(:player).permit(:name, :positions, :mlb_team, :calculated_value, :is_drafted)
  end
end
