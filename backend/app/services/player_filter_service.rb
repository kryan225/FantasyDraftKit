# frozen_string_literal: true

# PlayerFilterService
#
# Single source of truth for player filtering and sorting logic.
# Extracted from DraftBoardController, PlayersController, and DraftPicksController
# to eliminate ~150 lines of duplicated code (DRY principle).
#
# Usage:
#   players = PlayerFilterService.new(params).call
#
# Supported params:
#   - position:       Filter by position (uses Player.by_position scope)
#   - search:         Case-insensitive name search
#   - drafted:        "true" = drafted only, "false" = available only,
#                     "" = all players, absent = default to available
#   - interested:     "true" = interested players only
#   - multi_position: "true" = players with multiple positions only
#   - min_value:      Minimum calculated_value threshold (numeric)
#   - sort:           Column to sort by (whitelisted, see SORT_COLUMNS)
#   - direction:      "asc" or "desc" (default: "desc")
#
class PlayerFilterService
  STANDARD_SORT_COLUMNS = %w[name positions mlb_team calculated_value].freeze
  JSONB_SORT_COLUMNS = %w[
    home_runs runs rbi stolen_bases batting_average at_bats
    wins saves strikeouts era whip innings_pitched
  ].freeze
  SORT_COLUMNS = (STANDARD_SORT_COLUMNS + JSONB_SORT_COLUMNS).freeze

  def initialize(params)
    @params = params
  end

  def call
    players = Player.all
    players = apply_filters(players)
    players = apply_sorting(players)
    players
  end

  private

  attr_reader :params

  def apply_filters(players)
    players = filter_by_position(players)
    players = filter_by_search(players)
    players = filter_by_drafted_status(players)
    players = filter_by_interested(players)
    players = filter_by_multi_position(players)
    players = filter_by_min_value(players)
    players
  end

  # Flex positions map to multiple real positions:
  #   CI  → 1B or 3B
  #   MI  → 2B or SS
  #   P   → SP or RP
  #   UTIL → all players (no filter needed)
  FLEX_POSITION_MAP = {
    "CI" => %w[1B 3B],
    "MI" => %w[2B SS],
    "P" => %w[SP RP],
    "UTIL" => nil
  }.freeze

  def filter_by_position(players)
    return players unless params[:position].present?

    position = params[:position]

    if position == "UTIL"
      players
    elsif FLEX_POSITION_MAP.key?(position)
      conditions = FLEX_POSITION_MAP[position].map { |pos| "positions LIKE ?" }
      values = FLEX_POSITION_MAP[position].map { |pos| "%#{pos}%" }
      players.where(conditions.join(" OR "), *values)
    else
      players.by_position(position)
    end
  end

  def filter_by_search(players)
    return players unless params[:search].present?

    players.where("name ILIKE ?", "%#{params[:search]}%")
  end

  # Default to available players unless the caller explicitly passes a drafted param.
  # An empty string ("") means "show all" — distinct from the param being absent.
  def filter_by_drafted_status(players)
    if params.key?(:drafted)
      case params[:drafted]
      when "true"  then players.drafted
      when "false" then players.available
      else players # empty string → no filter
      end
    else
      players.available
    end
  end

  def filter_by_interested(players)
    return players unless params[:interested] == "true"

    players.with_any_interest
  end

  def filter_by_multi_position(players)
    return players unless params[:multi_position] == "true"

    players.multi_position
  end

  def filter_by_min_value(players)
    return players unless params[:min_value].present?

    min = params[:min_value].to_f
    players.where("calculated_value >= ?", min)
  end

  def apply_sorting(players)
    sort_column = params[:sort] || "calculated_value"
    sort_direction = normalize_direction(params[:direction])

    if STANDARD_SORT_COLUMNS.include?(sort_column)
      sort_standard_column(players, sort_column, sort_direction)
    elsif JSONB_SORT_COLUMNS.include?(sort_column)
      sort_jsonb_column(players, sort_column, sort_direction)
    else
      players.order(calculated_value: :desc)
    end
  end

  def normalize_direction(direction)
    %w[asc desc].include?(direction) ? direction : "desc"
  end

  def sort_standard_column(players, column, direction)
    if column == "calculated_value"
      players.order(Arel.sql("calculated_value #{direction} NULLS LAST"))
    else
      players.order(Arel.sql("#{column} #{direction}"))
    end
  end

  def sort_jsonb_column(players, column, direction)
    players.order(Arel.sql("(projections->>'#{column}')::float #{direction} NULLS LAST"))
  end
end
