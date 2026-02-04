class DraftPick < ApplicationRecord
  # Associations
  belongs_to :league
  belongs_to :team
  belongs_to :player

  # Validations
  validates :price, presence: true, numericality: { greater_than: 0 }
  validates :pick_number, presence: true, numericality: { greater_than: 0 }
  validates :player_id, uniqueness: { scope: :league_id, message: "has already been drafted in this league" }

  # Callbacks
  after_create :mark_player_as_drafted
  after_create :deduct_from_team_budget
  after_destroy :mark_player_as_available
  after_destroy :refund_team_budget

  # Scopes
  scope :keepers, -> { where(is_keeper: true) }
  scope :regular_picks, -> { where(is_keeper: false) }
  scope :for_league, ->(league_id) { where(league_id: league_id).order(:pick_number) }

  private

  def mark_player_as_drafted
    player.mark_as_drafted!
  end

  def mark_player_as_available
    player.mark_as_available!
  end

  def deduct_from_team_budget
    team.update(budget_remaining: team.budget_remaining - price)
  end

  def refund_team_budget
    team.update(budget_remaining: team.budget_remaining + price)
  end
end
