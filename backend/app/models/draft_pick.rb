class DraftPick < ApplicationRecord
  include PositionEligibility

  # Associations
  belongs_to :league
  belongs_to :team
  belongs_to :player

  # Validations
  validates :price, presence: true, numericality: { greater_than: 0 }
  validates :pick_number, presence: true, numericality: { greater_than: 0 }
  validates :player_id, uniqueness: { scope: :league_id, message: "has already been drafted in this league" }
  validates :drafted_position, presence: true
  validate :player_eligible_for_drafted_position
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
    # Only update if not already set (avoid conflicts with controller updates)
    player.update_columns(is_drafted: true, team_id: team_id) unless player.is_drafted && player.team_id == team_id
  end

  def mark_player_as_available
    # Only update if currently drafted (avoid conflicts)
    player.update_columns(is_drafted: false, team_id: nil) if player.is_drafted
  end

  def deduct_from_team_budget
    team.update(budget_remaining: team.budget_remaining - price)
  end

  def refund_team_budget
    team.update(budget_remaining: team.budget_remaining + price)
  end

  # Custom validation to check if player is eligible for the drafted position
  def player_eligible_for_drafted_position
    return unless drafted_position.present? && player.present?

    # Skip validation if this is an update (not a new record)
    return unless new_record?

    unless player_eligible_for_position?(player, drafted_position)
      eligible_positions = eligible_positions_for(player)
      errors.add(:drafted_position, "Player #{player.name} is not eligible for #{drafted_position}. Eligible positions: #{eligible_positions.join(', ')}")
    end
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
