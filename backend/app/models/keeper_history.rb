class KeeperHistory < ApplicationRecord
  # Associations
  belongs_to :player
  belongs_to :team

  # Validations
  validates :year, presence: true, numericality: { only_integer: true }
  validates :price, presence: true, numericality: { greater_than: 0 }
  validates :player_id, uniqueness: { scope: [:team_id, :year], message: "already has a keeper record for this team and year" }

  # Scopes
  scope :for_year, ->(year) { where(year: year) }
  scope :for_team, ->(team_id) { where(team_id: team_id) }
end
