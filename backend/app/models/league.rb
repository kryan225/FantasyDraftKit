class League < ApplicationRecord
  # Associations
  has_many :teams, dependent: :destroy
  has_many :draft_picks, dependent: :destroy
  has_many :keeper_histories, through: :teams

  # Validations
  validates :name, presence: true
  validates :team_count, presence: true, numericality: { greater_than: 0, less_than_or_equal_to: 20 }
  validates :auction_budget, presence: true, numericality: { greater_than: 0 }
  validates :keeper_limit, numericality: { greater_than_or_equal_to: 0 }, allow_nil: true
end
