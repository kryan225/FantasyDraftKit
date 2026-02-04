class PlayersController < ApplicationController
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
end
