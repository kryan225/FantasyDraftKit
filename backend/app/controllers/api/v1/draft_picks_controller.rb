class Api::V1::DraftPicksController < Api::V1::BaseController
  before_action :set_draft_pick, only: [:update, :destroy]
  before_action :set_league, only: [:index, :create]

  # GET /api/v1/leagues/:league_id/draft_picks
  def index
    @draft_picks = @league.draft_picks.includes(:team, :player).order(:pick_number)
    render json: @draft_picks, include: [:team, :player]
  end

  # POST /api/v1/leagues/:league_id/draft_picks
  def create
    @draft_pick = @league.draft_picks.new(draft_pick_params)

    # Auto-assign pick number if not provided
    if @draft_pick.pick_number.nil?
      @draft_pick.pick_number = @league.draft_picks.maximum(:pick_number).to_i + 1
    end

    if @draft_pick.save
      render json: @draft_pick, include: [:team, :player], status: :created
    else
      render json: { errors: @draft_pick.errors.full_messages }, status: :unprocessable_entity
    end
  end

  # PATCH/PUT /api/v1/draft_picks/:id
  def update
    if @draft_pick.update(draft_pick_params)
      render json: @draft_pick, include: [:team, :player]
    else
      render json: { errors: @draft_pick.errors.full_messages }, status: :unprocessable_entity
    end
  end

  # DELETE /api/v1/draft_picks/:id (Undo pick)
  def destroy
    @draft_pick.destroy
    head :no_content
  end

  private

  def set_draft_pick
    @draft_pick = DraftPick.find(params[:id])
  rescue ActiveRecord::RecordNotFound
    render json: { error: "Draft pick not found" }, status: :not_found
  end

  def set_league
    @league = League.find(params[:league_id])
  rescue ActiveRecord::RecordNotFound
    render json: { error: "League not found" }, status: :not_found
  end

  def draft_pick_params
    params.require(:draft_pick).permit(:team_id, :player_id, :price, :is_keeper, :pick_number)
  end
end
