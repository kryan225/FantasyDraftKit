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

    # Calculate per-team position needs matrix
    @team_needs_matrix = calculate_team_needs_matrix

    # Resolve selected team for nomination suggestions
    @my_team = @teams.find_by(id: params[:my_team]) if params[:my_team].present?
    @nomination_suggestions = @my_team ? calculate_nomination_suggestions : []
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

    # Direction 1: Can a flex player move TO this position (creating space at flex for new player)?
    flex_positions = get_flex_positions_for(position)
    flex_positions.each do |flex_pos|
      # CRITICAL: Check if flex position has space for the new player
      # For a swap to work, the new player needs somewhere to go (the flex position)
      flex_max = roster_config[flex_pos].to_i
      next if flex_max == 0 # Position not used in this league

      flex_filled = team.draft_picks.where(drafted_position: flex_pos).count
      next if flex_filled >= flex_max # No space at flex for new player

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

  def calculate_nomination_suggestions
    candidates = Player.available
                       .where("calculated_value > ?", 1.0)
                       .order(calculated_value: :desc)
                       .limit(100)

    return [] if candidates.empty?

    max_value = candidates.first.calculated_value.to_f
    opponent_teams = @teams.reject { |t| t.id == @my_team.id }
    fill_rate_lookup = @position_fill_rates.index_by { |fr| fr[:position] }

    scored = candidates.filter_map do |player|
      score_player_for_nomination(player, opponent_teams, fill_rate_lookup, max_value)
    end

    scored.sort_by { |s| -s[:score] }.first(15)
  end

  def score_player_for_nomination(player, opponent_teams, fill_rate_lookup, max_value)
    roster_positions = eligible_roster_positions(player)
    return nil if roster_positions.empty?

    best = nil

    roster_positions.each do |position|
      fill_data = fill_rate_lookup[position]
      next unless fill_data

      # Opponent demand: fraction of opponents who can draft this position
      demand_count = opponent_teams.count { |t| team_can_draft_position?(t, position) }
      next if demand_count == 0 # No opponents need it — useless nomination

      opponent_demand = demand_count.to_f / opponent_teams.size

      # Position scarcity: league-wide fill percentage (0.0 to 1.0)
      scarcity = fill_data[:fill_percentage].to_f / 100.0

      # Player value: normalized against max available
      value_norm = max_value > 0 ? player.calculated_value.to_f / max_value : 0.0

      # Your need: can your team draft this position?
      my_team_needs = team_can_draft_position?(@my_team, position)
      need_modifier = my_team_needs ? -0.3 : 0.5

      score = (opponent_demand * 0.35) +
              (scarcity * 0.20) +
              (value_norm * 0.25) +
              (need_modifier * 0.20)

      # Prefer positions where user does NOT need
      if best.nil? || score > best[:score] || (score == best[:score] && !my_team_needs)
        reasons = build_nomination_reasons(demand_count, opponent_teams.size, position,
                                           fill_data[:fill_percentage], my_team_needs)
        best = {
          player: player,
          score: score.round(3),
          target_position: position,
          opponent_demand: opponent_demand.round(2),
          my_team_needs: my_team_needs,
          reasons: reasons
        }
      end
    end

    best
  end

  # Returns roster positions (from the league config) this player is eligible for,
  # excluding BENCH.
  def eligible_roster_positions(player)
    roster_config = @league.roster_config || {}
    roster_config.select { |pos, slots| slots.to_i > 0 && pos != "BENCH" }
                 .keys
                 .select { |pos| player_eligible_for_position?(player, pos) }
  end

  def build_nomination_reasons(demand_count, opponent_count, position, fill_pct, my_team_needs)
    reasons = []
    reasons << "#{demand_count}/#{opponent_count} opponents need #{position}"
    reasons << "#{fill_pct.round(0).to_i}% filled" if fill_pct >= 25
    if my_team_needs
      reasons << "you also need #{position}"
    else
      reasons << "you don't need #{position}"
    end
    reasons
  end

  def calculate_team_needs_matrix
    roster_config = @league.roster_config || {}
    active_positions = roster_config.select { |pos, slots| slots.to_i > 0 && pos != "BENCH" }.keys
    total_roster_slots = roster_config.values.sum

    # Single aggregated query: { [team_id, drafted_position] => count }
    position_counts = @league.draft_picks.group(:team_id, :drafted_position).count

    # Pre-compute total filled per team
    team_totals = Hash.new(0)
    position_counts.each { |(team_id, _), count| team_totals[team_id] += count }

    teams_data = @teams.map do |team|
      total_filled = team_totals[team.id]
      roster_full = total_filled >= total_roster_slots

      needs = {}
      active_positions.each do |position|
        max_slots = roster_config[position].to_i
        filled = position_counts[[team.id, position]].to_i
        open_slots = max_slots - filled

        state = if roster_full
                  :closed
                elsif open_slots > 0
                  :open
                else
                  team_can_draft_position?(team, position) ? :flex : :closed
                end

        needs[position] = { state: state, open_slots: open_slots }
      end

      { team: team, total_filled: total_filled, total_slots: total_roster_slots, needs: needs }
    end

    { positions: active_positions, teams: teams_data }
  end

end
