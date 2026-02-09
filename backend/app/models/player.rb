class Player < ApplicationRecord
  # Associations
  belongs_to :team, optional: true
  has_many :draft_picks, dependent: :nullify
  has_many :keeper_histories, dependent: :destroy

  # Callbacks
  before_save :sync_drafted_status

  # Validations
  validates :name, presence: true
  validates :positions, presence: true
  validates :calculated_value, numericality: { greater_than_or_equal_to: 0 }, allow_nil: true

  # Scopes
  scope :drafted, -> { where(is_drafted: true) }
  scope :available, -> { where(is_drafted: [false, nil]) }  # Available means not explicitly drafted
  scope :by_position, ->(position) { where("positions LIKE ?", "%#{position}%") }
  scope :interested, -> { where(interested: true) }

  # Instance Methods
  def mark_as_drafted!
    update(is_drafted: true)
  end

  def mark_as_available!
    update(is_drafted: false)
  end

  def toggle_interested!
    update(interested: !interested)
  end

  private

  def sync_drafted_status
    # Automatically sync is_drafted with team_id presence
    self.is_drafted = team_id.present?
  end
end
