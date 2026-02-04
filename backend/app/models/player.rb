class Player < ApplicationRecord
  # Associations
  has_many :draft_picks, dependent: :nullify
  has_many :keeper_histories, dependent: :destroy

  # Validations
  validates :name, presence: true
  validates :positions, presence: true
  validates :calculated_value, numericality: { greater_than_or_equal_to: 0 }, allow_nil: true

  # Scopes
  scope :drafted, -> { where(is_drafted: true) }
  scope :available, -> { where(is_drafted: false) }
  scope :by_position, ->(position) { where("positions LIKE ?", "%#{position}%") }

  # Instance Methods
  def mark_as_drafted!
    update(is_drafted: true)
  end

  def mark_as_available!
    update(is_drafted: false)
  end
end
