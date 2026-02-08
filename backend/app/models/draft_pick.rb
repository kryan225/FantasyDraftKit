class DraftPick < ApplicationRecord
  # Associations
  belongs_to :league
  belongs_to :team
  belongs_to :player

  # Validations
  validates :price, presence: true, numericality: { greater_than: 0 }
  validates :pick_number, presence: true, numericality: { greater_than: 0 }
  validates :player_id, uniqueness: { scope: :league_id, message: "has already been drafted in this league" }
  validates :drafted_position, presence: true
  validate :team_has_available_roster_slot

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

  # Custom validation to check if team has an available roster slot
  def team_has_available_roster_slot
    return unless drafted_position.present? && team.present?

    # Skip validation if this is an update (not a new record)
    return unless new_record?

    position_status = team.position_available?(drafted_position)

    unless position_status[:available]
      errors.add(:drafted_position, "#{drafted_position} position is full (#{position_status[:slots_used]}/#{position_status[:slots_total]})")
    end
  end
end
