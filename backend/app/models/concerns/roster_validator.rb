# frozen_string_literal: true

# RosterValidator - Validates roster positions against league roster configuration
#
# This module provides roster validation logic for teams:
# - Checks if a team has available slots at a given position
# - Calculates current roster counts by position
# - Validates draft picks against roster limits
#
# Follows Single Responsibility Principle by encapsulating roster validation logic.
module RosterValidator
  extend ActiveSupport::Concern

  # Check if team has an available slot at the given position
  #
  # @param position [String] The position to check (e.g., "1B", "OF", "SP")
  # @return [Hash] { available: Boolean, slots_used: Integer, slots_total: Integer, message: String }
  def position_available?(position)
    roster_config = league.roster_config || {}
    slots_total = roster_config[position] || 0

    if slots_total == 0
      return {
        available: false,
        slots_used: 0,
        slots_total: 0,
        message: "Position #{position} is not in the roster configuration"
      }
    end

    slots_used = count_position_usage(position)

    {
      available: slots_used < slots_total,
      slots_used: slots_used,
      slots_total: slots_total,
      message: slots_used < slots_total ? "Available" : "Position full (#{slots_used}/#{slots_total})"
    }
  end

  # Count how many roster slots are currently used at the given position
  #
  # @param position [String] The position to count
  # @return [Integer] Number of players drafted at this position
  def count_position_usage(position)
    draft_picks.where(drafted_position: position).count
  end

  # Get roster status for all positions
  #
  # @return [Hash] Position => { used: Integer, total: Integer, available: Integer }
  def roster_status
    roster_config = league.roster_config || {}

    roster_config.each_with_object({}) do |(position, total), result|
      used = count_position_usage(position)
      result[position] = {
        used: used,
        total: total,
        available: total - used
      }
    end
  end

  # Check if team's roster is full
  #
  # @return [Boolean]
  def roster_full?
    return false unless league.roster_config

    total_slots = league.roster_config.values.sum
    draft_picks.count >= total_slots
  end

  # Get available positions for a new draft pick
  # Returns only positions that still have available slots
  #
  # @return [Array<String>] List of position names that are not full
  def available_positions
    roster_config = league.roster_config || {}

    roster_config.select do |position, total|
      count_position_usage(position) < total
    end.keys
  end
end
