# frozen_string_literal: true

# PositionEligibility - Centralized position eligibility logic
#
# This concern provides methods to determine if a player can fill a roster position,
# accounting for flex positions (UTIL, MI, CI) and their eligibility rules.
#
# Eligibility Rules:
# - UTIL: Can be filled by any batter (C, 1B, 2B, 3B, SS, OF)
# - MI: Can be filled by middle infielders (2B, SS)
# - CI: Can be filled by corner infielders (1B, 3B)
# - Standard positions: Direct match required (C, 1B, 2B, 3B, SS, OF, SP, RP, BENCH)
# - BENCH: Can hold any player (batters and pitchers)
module PositionEligibility
  extend ActiveSupport::Concern

  # Determines if a player can fill a specific roster position
  #
  # @param player [Player] The player to check eligibility for
  # @param position [String] The roster position to check (e.g., "C", "UTIL", "MI")
  # @return [Boolean] true if player can fill the position, false otherwise
  def player_eligible_for_position?(player, position)
    positions = player.positions.to_s.split(',').map(&:strip)

    case position
    when "UTIL"
      # UTIL accepts any batter position
      (positions & ["C", "1B", "2B", "3B", "SS", "OF"]).any?
    when "MI"
      # MI (Middle Infield) accepts 2B or SS
      (positions & ["2B", "SS"]).any?
    when "CI"
      # CI (Corner Infield) accepts 1B or 3B
      (positions & ["1B", "3B"]).any?
    when "BENCH"
      # BENCH accepts any player
      true
    else
      # Standard positions require direct match
      positions.include?(position)
    end
  end

  # Returns the flex positions that can serve as alternatives for a given position
  #
  # For example, a catcher (C) can also occupy UTIL, MI, or CI slots if eligible
  #
  # @param position [String] The roster position to find flex alternatives for
  # @return [Array<String>] Array of flex position names
  def get_flex_positions_for(position)
    case position
    when "C", "1B", "2B", "3B", "SS", "OF"
      # Batter positions can use any flex spot
      ["UTIL", "MI", "CI"]
    when "MI"
      # MI can take from UTIL
      ["UTIL"]
    when "CI"
      # CI can take from UTIL
      ["UTIL"]
    when "SP", "RP", "BENCH"
      # Pitchers and bench don't have flex positions
      []
    else
      []
    end
  end

  # Returns all positions a player is eligible to fill
  #
  # This includes their natural positions plus any flex positions they qualify for
  #
  # @param player [Player] The player to get eligible positions for
  # @return [Array<String>] Array of position names the player can fill
  def eligible_positions_for(player)
    positions = player.positions.to_s.split(',').map(&:strip)
    eligible = positions.dup

    # Add flex positions based on eligibility
    eligible << "UTIL" if player_eligible_for_position?(player, "UTIL")
    eligible << "MI" if player_eligible_for_position?(player, "MI")
    eligible << "CI" if player_eligible_for_position?(player, "CI")
    eligible << "BENCH" # Everyone can go to bench

    eligible.uniq
  end

  # Standard batter positions
  BATTER_POSITIONS = ["C", "1B", "2B", "3B", "SS", "OF"].freeze

  # Standard pitcher positions
  PITCHER_POSITIONS = ["SP", "RP"].freeze

  # Flex positions
  FLEX_POSITIONS = ["UTIL", "MI", "CI"].freeze

  # All standard roster positions
  ALL_POSITIONS = (BATTER_POSITIONS + PITCHER_POSITIONS + FLEX_POSITIONS + ["BENCH"]).freeze
end
