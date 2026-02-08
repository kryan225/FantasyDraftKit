class Team < ApplicationRecord
  include RosterValidator

  # Associations
  belongs_to :league
  has_many :draft_picks, dependent: :destroy
  has_many :keeper_histories, dependent: :destroy
  has_many :players, through: :draft_picks

  # Validations
  validates :name, presence: true
  validates :budget_remaining, numericality: { greater_than_or_equal_to: 0 }, allow_nil: true

  # Callbacks
  before_validation :set_initial_budget, on: :create

  private

  def set_initial_budget
    self.budget_remaining ||= league&.auction_budget
  end
end
