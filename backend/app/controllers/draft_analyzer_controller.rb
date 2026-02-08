class DraftAnalyzerController < ApplicationController
  include LeagueResolvable
  include PositionEligibility

  before_action :ensure_league

  def show
    @league = current_league
    return unless @league

    @teams = @league.teams.order(:name)

    # Calculate roster fill rate by position
    @position_fill_rates = calculate_position_fill_rates
  end

  private

  def calculate_position_fill_rates
    # Get total slots per position from roster configuration
    roster_config = @league.roster_config || {}
    team_count = @league.team_count

    # Count filled slots by position (using drafted_position)
    filled_by_position = @league.draft_picks.group(:drafted_position).count

    # Build analysis for each position
    ALL_POSITIONS.map do |position|
      slots_per_team = roster_config[position].to_i
      next if slots_per_team == 0 # Skip positions not used in this league

      total_slots = slots_per_team * team_count
      filled_slots = filled_by_position[position].to_i
      available_slots = total_slots - filled_slots
      fill_percentage = total_slots > 0 ? (filled_slots.to_f / total_slots * 100).round(1) : 0

      # Calculate which teams can still draft this position (one-level lookahead)
      teams_can_draft = @teams.select { |team| team_can_draft_position?(team, position) }

      {
        position: position,
        total_slots: total_slots,
        filled_slots: filled_slots,
        available_slots: available_slots,
        fill_percentage: fill_percentage,
        teams_can_draft: teams_can_draft,
        teams_can_draft_count: teams_can_draft.count
      }
    end.compact
  end

  def team_can_draft_position?(team, position)
    roster_config = @league.roster_config || {}

    # CRITICAL: Check if team's entire roster is full first
    total_roster_slots = roster_config.values.sum
    total_filled = team.draft_picks.count
    return false if total_filled >= total_roster_slots

    max_slots = roster_config[position].to_i

    # Count how many are currently at this position
    filled_slots = team.draft_picks.where(drafted_position: position).count

    # If under max, they have room
    return true if filled_slots < max_slots

    # Bidirectional lookahead: Check both directions for flexibility

    # Direction 1: Can a flex player move TO this position?
    flex_positions = get_flex_positions_for(position)
    flex_positions.each do |flex_pos|
      # Find players in flex position who are eligible for this position
      moveable_players = team.draft_picks.where(drafted_position: flex_pos).select do |pick|
        player_eligible_for_position?(pick.player, position)
      end

      return true if moveable_players.any?
    end

    # Direction 2: Can a player at this position move OUT to ANY other position with space?
    current_players = team.draft_picks.where(drafted_position: position)

    ALL_POSITIONS.each do |target_pos|
      next if target_pos == position # Can't move to same position

      # Check if target position has available slots
      target_max = roster_config[target_pos].to_i
      next if target_max == 0 # Position not used in this league

      target_filled = team.draft_picks.where(drafted_position: target_pos).count
      next if target_filled >= target_max # Target position is full

      # Check if any current player at this position could move to the target position
      moveable_players = current_players.select do |pick|
        player_eligible_for_position?(pick.player, target_pos)
      end

      return true if moveable_players.any?
    end

    false
  end

end
