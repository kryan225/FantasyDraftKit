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

    # Calculate spending split between batting and pitching
    @spending_splits = calculate_spending_splits

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
      teams_cant_draft = @teams.reject { |team| team_can_draft_position?(team, position) }

      # For teams that can't draft, find the players blocking the position
      teams_cant_draft_with_blockers = teams_cant_draft.map do |team|
        { team: team, blocking_players: blocking_players_for_position(team, position) }
      end

      {
        position: position,
        total_slots: total_slots,
        filled_slots: filled_slots,
        available_slots: available_slots,
        fill_percentage: fill_percentage,
        teams_can_draft: teams_can_draft,
        teams_can_draft_count: teams_can_draft.count,
        teams_cant_draft: teams_cant_draft_with_blockers
      }
    end.compact
  end

  # Capacity-based check: can a team draft one more player at this position?
  #
  # 1. Determine which player positions can fill this roster slot (e.g., MI → 2B, SS)
  # 2. Count all roster slots that accept any of those player positions
  # 3. Count players on the team with any of those positions
  # 4. If count < capacity, team has room
  def team_can_draft_position?(team, position)
    roster_config = @league.roster_config || {}
    return false if team.draft_picks.count >= roster_config.values.sum

    player_positions = player_positions_for_slot(position)
    capacity = roster_capacity_for(roster_config, player_positions)
    eligible_count = count_eligible_players(team, player_positions)

    eligible_count < capacity
  end

  # For teams that can't draft a position, list all players occupying competing slots.
  # E.g., for C: show players at C slots AND UTIL slots (since UTIL can hold a C player).
  def blocking_players_for_position(team, position)
    player_positions = player_positions_for_slot(position)

    # Find all roster slots that could hold a player eligible for this position
    competing_slots = (@league.roster_config || {}).keys.select do |slot|
      next false if slot == "BENCH"
      slot_accepts = player_positions_for_slot(slot)
      (slot_accepts & player_positions).any?
    end

    # Show all players sitting in those competing slots
    team.draft_picks.includes(:player).select { |dp|
      competing_slots.include?(dp.drafted_position)
    }.map { |dp| "#{dp.player.name} (#{dp.drafted_position})" }
  end

  # Which real player positions can fill a given roster slot?
  # MI is a slot, not a player position — players have 2B or SS.
  def player_positions_for_slot(slot)
    case slot
    when "MI" then %w[2B SS]
    when "CI" then %w[1B 3B]
    when "UTIL" then %w[C 1B 2B 3B SS OF SP RP]
    else [slot]
    end
  end

  # How many roster slots can hold players with any of the given positions?
  def roster_capacity_for(roster_config, player_positions)
    roster_config.sum do |slot, count|
      next 0 if slot == "BENCH" || count.to_i == 0

      slot_accepts = player_positions_for_slot(slot)
      (slot_accepts & player_positions).any? ? count.to_i : 0
    end
  end

  # Count players on a team who have any of the given positions.
  def count_eligible_players(team, player_positions)
    team.draft_picks.includes(:player).count do |pick|
      (pick.player.positions.to_s.split(/[,\/]/).map(&:strip) & player_positions).any?
    end
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

  # Returns natural roster positions (from the league config) this player is eligible for,
  # excluding BENCH and flex positions (UTIL, MI, CI) which aren't useful for nomination targeting.
  def eligible_roster_positions(player)
    roster_config = @league.roster_config || {}
    roster_config.select { |pos, slots| slots.to_i > 0 && !%w[BENCH UTIL MI CI].include?(pos) }
                 .keys
                 .select { |pos| player_eligible_for_position?(player, pos) }
  end

  def build_nomination_reasons(demand_count, opponent_count, position, fill_pct, my_team_needs)
    reasons = []
    reasons << "#{demand_count}/#{opponent_count} opponents need #{position}"
    reasons << "#{fill_pct.round(0).to_i}% filled"
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

  def calculate_spending_splits
    pitcher_positions = %w[SP RP]
    budget = @league.auction_budget

    # Single query: { [team_id, drafted_position] => sum(price) }
    spending = @league.draft_picks.group(:team_id, :drafted_position).sum(:price)

    @teams.map do |team|
      batting_spend = 0
      pitching_spend = 0

      spending.each do |(tid, pos), amount|
        next unless tid == team.id
        if pitcher_positions.include?(pos)
          pitching_spend += amount
        else
          batting_spend += amount
        end
      end

      total_spend = batting_spend + pitching_spend
      batting_pct = total_spend > 0 ? (batting_spend.to_f / total_spend * 100).round(1) : 0
      pitching_pct = total_spend > 0 ? (pitching_spend.to_f / total_spend * 100).round(1) : 0

      {
        team: team,
        batting_spend: batting_spend,
        pitching_spend: pitching_spend,
        total_spend: total_spend,
        remaining: budget - total_spend,
        batting_pct: batting_pct,
        pitching_pct: pitching_pct
      }
    end.sort_by { |s| -s[:total_spend] }
  end

end
