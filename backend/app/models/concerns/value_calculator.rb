# frozen_string_literal: true

# ValueCalculator
#
# Implements z-score based auction value calculation for fantasy baseball players.
#
# Algorithm Overview:
# 1. Separate hitters vs pitchers by position
# 2. Calculate z-scores for each stat category (standardize: (value - mean) / stddev)
# 3. Determine replacement level per position (e.g., 24th best C for 12-team league)
# 4. Calculate value above replacement (z-score minus replacement z-score, floored at 0)
# 5. Convert to dollars using 67% hitter / 33% pitcher budget split, minimum $1
#
# Categories:
# - Hitters (5): HR, R, RBI, SB, AVG (weighted by AB)
# - Pitchers (5): W, SV, K, ERA (inverted), WHIP (inverted)
#
# Position Scarcity:
# - Replacement = Nth best player where N = total roster slots for position
# - C: 24th best (12 teams × 2 slots), OF: 60th best (12 teams × 5 slots), etc.
# - Multi-position players use best (lowest) replacement threshold
#
# Why z-scores?
# - Proven methodology used by industry (ESPN, Yahoo)
# - Computationally simple (~100-200ms for 200 players)
# - Balances all categories fairly (each has mean=0, stddev=1)
# - Easier to maintain than SGP (Standings Gain Points)
#
# Why position-based replacement?
# - Reflects market reality (catchers are scarce, outfielders plentiful)
# - Multi-position players valued correctly (can fill scarce positions)
# - Matches auction draft behavior
#
module ValueCalculator
  extend ActiveSupport::Concern

  # Hitter stat categories (5 total)
  HITTER_CATEGORIES = {
    hr: { field: 'home_runs', invert: false, rate: false },
    r: { field: 'runs', invert: false, rate: false },
    rbi: { field: 'rbi', invert: false, rate: false },
    sb: { field: 'stolen_bases', invert: false, rate: false },
    avg: { field: 'batting_average', invert: false, rate: true, volume_field: 'at_bats' }
  }.freeze

  # Pitcher stat categories (5 total)
  # Field names must match keys stored by DataControlController#parse_pitcher_stats
  PITCHER_CATEGORIES = {
    w: { field: 'wins', invert: false, rate: false },
    sv: { field: 'saves', invert: false, rate: false },
    k: { field: 'strikeouts', invert: false, rate: false },
    era: { field: 'era', invert: true, rate: true, volume_field: 'innings_pitched' },
    whip: { field: 'whip', invert: true, rate: true, volume_field: 'innings_pitched' }
  }.freeze

  # Budget allocation (industry standard)
  HITTER_BUDGET_PERCENT = 0.67
  PITCHER_BUDGET_PERCENT = 0.33

  # Public API - orchestrates full value calculation
  #
  # @param league [League] The league to calculate values for
  # @return [Hash] Summary statistics: { count:, min_value:, max_value:, avg_value: }
  def recalculate_values(league)
    # Step 1: Separate players by type
    players_by_type = separate_players_by_type(league)
    hitters = players_by_type[:hitters]
    pitchers = players_by_type[:pitchers]

    return { count: 0, min_value: 0, max_value: 0, avg_value: 0 } if hitters.empty? && pitchers.empty?

    # Step 2: Calculate z-scores for each group
    hitter_zscores = calculate_z_scores(hitters, HITTER_CATEGORIES)
    pitcher_zscores = calculate_z_scores(pitchers, PITCHER_CATEGORIES)

    # Step 3: Determine replacement level per position
    hitter_replacements = calculate_replacement_levels(league, hitters, hitter_zscores)
    pitcher_replacements = calculate_replacement_levels(league, pitchers, pitcher_zscores)

    # Step 4: Calculate value above replacement
    hitter_var = calculate_value_above_replacement(hitters, hitter_zscores, hitter_replacements)
    pitcher_var = calculate_value_above_replacement(pitchers, pitcher_zscores, pitcher_replacements)

    # Step 5: Convert to dollars with budget split
    hitter_dollars = convert_to_dollars(hitter_var, league, is_hitter: true)
    pitcher_dollars = convert_to_dollars(pitcher_var, league, is_hitter: false)

    # Bulk update all players at once (performance optimization)
    all_values = hitter_dollars.merge(pitcher_dollars)
    update_player_values(all_values)

    # Return summary statistics
    values = all_values.values
    {
      count: values.size,
      min_value: values.min || 0,
      max_value: values.max || 0,
      avg_value: values.sum / values.size.to_f
    }
  end

  private

  # Phase 1: Separate players into hitters and pitchers
  #
  # Hitter: positions include C, 1B, 2B, 3B, SS, OF (or multi-position like 2B/SS)
  # Pitcher: positions include SP, RP
  #
  # @param league [League] The league context
  # @return [Hash] { hitters: [Player], pitchers: [Player] }
  def separate_players_by_type(league)
    players = Player.where(is_drafted: false).to_a
    players.reject! { |p| skip_player?(p) }

    hitters = players.select { |p| hitter?(p) }
    pitchers = players.select { |p| pitcher?(p) }

    { hitters: hitters, pitchers: pitchers }
  end

  # Check if player is a hitter
  def hitter?(player)
    positions = player.positions.to_s.split(/[,\/]/).map(&:strip)
    (positions & %w[C 1B 2B 3B SS OF]).any?
  end

  # Check if player is a pitcher
  def pitcher?(player)
    positions = player.positions.to_s.split(/[,\/]/).map(&:strip)
    (positions & %w[SP RP]).any?
  end

  # Skip players with missing critical projections
  def skip_player?(player)
    return true if player.projections.blank?

    if hitter?(player)
      # Hitters need at_bats and at least one counting stat
      ab = player.projections['at_bats'].to_f
      hr = player.projections['home_runs'].to_f
      return true if ab <= 0 || (hr == 0 && player.projections['runs'].to_f == 0 && player.projections['rbi'].to_f == 0)
    elsif pitcher?(player)
      # Pitchers need innings_pitched and at least one counting stat
      ip = player.projections['innings_pitched'].to_f
      w = player.projections['wins'].to_f
      return true if ip <= 0 || (w == 0 && player.projections['saves'].to_f == 0 && player.projections['strikeouts'].to_f == 0)
    else
      return true # Not a valid hitter or pitcher
    end

    false
  end

  # Phase 2: Calculate z-scores for each player
  #
  # Z-score standardizes stats: z = (value - mean) / stddev
  # This makes all stats comparable (mean=0, stddev=1)
  #
  # @param players [Array<Player>] Players to calculate for
  # @param categories [Hash] Stat categories configuration
  # @return [Hash] { player_id => { total_z: Float, categories: { hr: Float, ... } } }
  def calculate_z_scores(players, categories)
    return {} if players.empty?

    z_scores = {}

    # Calculate z-score for each category
    categories.each do |category_key, config|
      category_z_scores = calculate_category_z_score(players, config)

      # Store each player's z-score for this category
      category_z_scores.each do |player_id, z_score|
        z_scores[player_id] ||= { total_z: 0.0, categories: {} }
        z_scores[player_id][:categories][category_key] = z_score
        z_scores[player_id][:total_z] += z_score
      end
    end

    z_scores
  end

  # Calculate z-score for a single stat category
  #
  # @param players [Array<Player>] Players to calculate for
  # @param config [Hash] Category configuration (:field, :invert, :rate, :volume_field)
  # @return [Hash] { player_id => z_score }
  def calculate_category_z_score(players, config)
    field = config[:field]
    invert = config[:invert]
    rate = config[:rate]

    # Extract values for this category
    if rate
      # Rate stats (AVG, ERA, WHIP) need weighted mean
      values, weights = extract_weighted_values(players, field, config[:volume_field])
      mean = calculate_weighted_mean(values, weights)

      # For stddev, calculate weighted variance
      variance = calculate_weighted_variance(values, weights, mean)
      stddev = Math.sqrt(variance)
    else
      # Counting stats (HR, R, RBI, SB, W, SV, K)
      values = players.map { |p| p.projections[field].to_f }
      mean = calculate_mean(values)
      stddev = calculate_stddev(values, mean)
    end

    # Handle edge case: all values identical (stddev = 0)
    return players.each_with_object({}) { |p, h| h[p.id] = 0.0 } if stddev.zero?

    # Calculate z-score for each player
    z_scores = {}
    players.each do |player|
      value = player.projections[field].to_f
      z_score = (value - mean) / stddev

      # Invert for ERA/WHIP (lower is better)
      z_score = -z_score if invert

      z_scores[player.id] = z_score
    end

    z_scores
  end

  # Extract values and weights for rate stats
  def extract_weighted_values(players, field, volume_field)
    values = []
    weights = []

    players.each do |player|
      value = player.projections[field].to_f
      weight = player.projections[volume_field].to_f

      if weight > 0
        values << value
        weights << weight
      end
    end

    [values, weights]
  end

  # Calculate weighted mean (e.g., league AVG = total hits / total AB)
  def calculate_weighted_mean(values, weights)
    return 0.0 if weights.empty? || weights.sum.zero?

    weighted_sum = values.zip(weights).sum { |v, w| v * w }
    weighted_sum / weights.sum
  end

  # Calculate weighted variance for rate stats
  def calculate_weighted_variance(values, weights, mean)
    return 0.0 if weights.empty? || weights.sum.zero?

    weighted_sq_diff = values.zip(weights).sum { |v, w| w * (v - mean)**2 }
    weighted_sq_diff / weights.sum
  end

  # Calculate mean of array
  def calculate_mean(values)
    return 0.0 if values.empty?
    values.sum / values.size.to_f
  end

  # Calculate standard deviation
  def calculate_stddev(values, mean)
    return 0.0 if values.size <= 1

    variance = values.sum { |v| (v - mean)**2 } / values.size.to_f
    Math.sqrt(variance)
  end

  # Phase 3: Calculate replacement level for each position
  #
  # Replacement = z-score of Nth best player where N = total roster slots
  # Example: 12 teams × 2 catchers = 24th best catcher is replacement
  #
  # @param league [League] League with roster configuration
  # @param players [Array<Player>] Players to evaluate
  # @param z_scores [Hash] Player z-scores from Phase 2
  # @return [Hash] { "C" => z_score, "1B" => z_score, ... }
  def calculate_replacement_levels(league, players, z_scores)
    roster_config = league.roster_config
    replacement_levels = {}

    roster_config.each do |position, slots|
      next if position == 'BENCH' # Bench doesn't affect replacement
      next if slots.zero?

      # Find all players eligible for this position
      eligible_players = players.select do |player|
        eligible_for_position?(player.positions, position)
      end

      # Sort by z-score descending (best first)
      eligible_players.sort_by! { |p| -z_scores.dig(p.id, :total_z).to_f }

      # Replacement level = z-score of (team_count × slots)th player
      replacement_index = league.team_count * slots

      if replacement_index <= eligible_players.size
        replacement_player = eligible_players[replacement_index - 1]
        replacement_levels[position] = z_scores.dig(replacement_player.id, :total_z).to_f
      else
        # Not enough players at this position - use lowest z-score
        replacement_levels[position] = eligible_players.empty? ? 0.0 : z_scores.dig(eligible_players.last.id, :total_z).to_f
      end
    end

    replacement_levels
  end

  # Phase 4: Calculate value above replacement (VAR)
  #
  # VAR = player's z-score - replacement z-score for their position
  # Multi-position players get best (lowest) replacement level
  # Floor VAR at 0 (no negative values)
  #
  # @param players [Array<Player>] Players to evaluate
  # @param z_scores [Hash] Player z-scores
  # @param replacement_levels [Hash] Replacement z-scores per position
  # @return [Hash] { player_id => var_value }
  def calculate_value_above_replacement(players, z_scores, replacement_levels)
    var_values = {}

    players.each do |player|
      player_z = z_scores.dig(player.id, :total_z).to_f
      replacement_z = best_replacement_level_for_player(player, replacement_levels)

      # VAR floored at 0 (can't be below replacement)
      var = [player_z - replacement_z, 0.0].max
      var_values[player.id] = var
    end

    var_values
  end

  # Get best (lowest) replacement level for a multi-position player
  #
  # Example: A 2B/SS player can fill either position, so use whichever
  # has the lower replacement level (harder to fill = more valuable)
  def best_replacement_level_for_player(player, replacement_levels)
    positions = player.positions.to_s.split(/[,\/]/).map(&:strip)

    # Find all positions this player can fill
    eligible_positions = replacement_levels.keys.select do |position|
      eligible_for_position?(player.positions, position)
    end

    # Return lowest replacement level (best for player value)
    eligible_positions.map { |pos| replacement_levels[pos] }.min || 0.0
  end

  # Phase 5: Convert VAR to auction dollars
  #
  # Budget split: 67% hitters, 33% pitchers (industry standard)
  # Dollar per point = available_budget / total_positive_var
  # Floor each player at $1 minimum
  #
  # @param var_values [Hash] { player_id => var }
  # @param league [League] League with budget info
  # @param is_hitter [Boolean] True for hitters, false for pitchers
  # @return [Hash] { player_id => dollar_value }
  def convert_to_dollars(var_values, league, is_hitter:)
    # Calculate budget for this player type
    total_budget = league.auction_budget * league.team_count
    type_budget = total_budget * (is_hitter ? HITTER_BUDGET_PERCENT : PITCHER_BUDGET_PERCENT)

    # Reserve $1 per roster slot
    roster_slots = calculate_roster_slots(league, is_hitter)
    available_budget = type_budget - roster_slots

    # Sum all positive VAR values
    total_var = var_values.values.sum

    # Handle edge case: no positive VAR (all at/below replacement)
    return var_values.transform_values { 1.0 } if total_var.zero?

    # Calculate dollar per VAR point
    dollar_per_var = available_budget / total_var

    # Convert each player's VAR to dollars, floor at $1
    var_values.transform_values do |var|
      [var * dollar_per_var + 1.0, 1.0].max
    end
  end

  # Calculate total roster slots for hitters or pitchers
  def calculate_roster_slots(league, is_hitter)
    roster_config = league.roster_config

    if is_hitter
      hitter_positions = %w[C 1B 2B 3B SS MI CI OF UTIL]
      hitter_positions.sum { |pos| roster_config[pos].to_i }
    else
      pitcher_positions = %w[SP RP]
      pitcher_positions.sum { |pos| roster_config[pos].to_i }
    end
  end

  # Bulk update player values in database (single UPDATE query)
  def update_player_values(values_by_id)
    return if values_by_id.empty?

    # Build SQL CASE statement for bulk update
    # UPDATE players SET calculated_value = CASE
    #   WHEN id = 1 THEN 45.2
    #   WHEN id = 2 THEN 38.7
    #   ...
    # END WHERE id IN (1, 2, ...)

    player_ids = values_by_id.keys
    case_statement = values_by_id.map do |id, value|
      "WHEN id = #{id} THEN #{value.round(2)}"
    end.join(' ')

    Player.where(id: player_ids).update_all(
      "calculated_value = CASE #{case_statement} END"
    )
  end

  # Check if a player's positions make them eligible for a roster position
  #
  # This is a simplified version of PositionEligibility for use in value calculation
  #
  # @param player_positions [String] Player's positions (e.g., "2B/SS", "OF")
  # @param roster_position [String] Roster position to check (e.g., "MI", "UTIL", "OF")
  # @return [Boolean] true if player can fill the roster position
  def eligible_for_position?(player_positions, roster_position)
    positions = player_positions.to_s.split(/[,\/]/).map(&:strip)

    case roster_position
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
      positions.include?(roster_position)
    end
  end
end
