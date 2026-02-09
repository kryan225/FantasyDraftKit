class StandingsController < ApplicationController
  include LeagueResolvable

  before_action :ensure_league

  def index
    @league = current_league
    return unless @league

    @teams = @league.teams.includes(draft_picks: :player).order(:name)

    # Calculate aggregate stats for each team
    @team_stats = @teams.map do |team|
      stats = calculate_team_stats(team)
      { team: team, stats: stats }
    end

    # Rank teams in each category (higher is better, except ERA and WHIP where lower is better)
    @rankings = calculate_rankings(@team_stats)
  end

  private

  def calculate_team_stats(team)
    players = team.draft_picks.includes(:player).map(&:player)

    # Initialize stat accumulators
    stats = {
      # Counting stats
      home_runs: 0,
      runs: 0,
      rbi: 0,
      stolen_bases: 0,
      wins: 0,
      saves: 0,
      strikeouts: 0,

      # Components for rate stats
      total_at_bats: 0,
      total_hits: 0,
      total_innings_pitched: 0,
      total_earned_runs: 0,
      total_whip_components: 0,

      # Final rate stats (calculated after)
      batting_average: 0.0,
      era: 0.0,
      whip: 0.0
    }

    players.each do |player|
      next unless player.projections.present?

      projections = player.projections

      # Accumulate counting stats
      stats[:home_runs] += projections["home_runs"].to_f
      stats[:runs] += projections["runs"].to_f
      stats[:rbi] += projections["rbi"].to_f
      stats[:stolen_bases] += projections["stolen_bases"].to_f
      stats[:wins] += projections["wins"].to_f
      stats[:saves] += projections["saves"].to_f
      stats[:strikeouts] += projections["strikeouts"].to_f

      # Accumulate components for batting average
      ab = projections["at_bats"].to_f
      avg = projections["batting_average"].to_f
      if ab > 0 && avg > 0
        stats[:total_at_bats] += ab
        stats[:total_hits] += (avg * ab)
      end

      # Accumulate components for ERA
      ip = projections["innings_pitched"].to_f
      era = projections["era"].to_f
      if ip > 0 && era > 0
        stats[:total_innings_pitched] += ip
        stats[:total_earned_runs] += (era * ip / 9.0)
      end

      # Accumulate components for WHIP
      whip = projections["whip"].to_f
      if ip > 0 && whip > 0
        stats[:total_whip_components] += (whip * ip)
      end
    end

    # Calculate rate stats
    if stats[:total_at_bats] > 0
      stats[:batting_average] = (stats[:total_hits] / stats[:total_at_bats]).round(3)
    end

    if stats[:total_innings_pitched] > 0
      stats[:era] = ((stats[:total_earned_runs] / stats[:total_innings_pitched]) * 9.0).round(2)
      stats[:whip] = (stats[:total_whip_components] / stats[:total_innings_pitched]).round(3)
    end

    stats
  end

  def calculate_rankings(team_stats)
    categories = {
      # Hitter categories (higher is better)
      home_runs: :desc,
      runs: :desc,
      rbi: :desc,
      stolen_bases: :desc,
      batting_average: :desc,

      # Pitcher categories
      wins: :desc,
      saves: :desc,
      strikeouts: :desc,
      era: :asc,  # Lower is better
      whip: :asc  # Lower is better
    }

    rankings = {}

    categories.each do |category, direction|
      # Sort teams by this category
      sorted = team_stats.sort_by { |ts| ts[:stats][category] }
      sorted.reverse! if direction == :desc

      # Assign ranks (handle ties by giving same rank)
      current_rank = 1
      previous_value = nil

      sorted.each_with_index do |team_stat, index|
        value = team_stat[:stats][category]

        # If value is same as previous, use same rank
        if previous_value && value == previous_value
          # Use same rank as previous
        else
          current_rank = index + 1
        end

        rankings[team_stat[:team].id] ||= {}
        rankings[team_stat[:team].id][category] = current_rank

        previous_value = value
      end
    end

    # Calculate total rotisserie points (sum of ranks)
    rankings.each do |team_id, category_ranks|
      rankings[team_id][:total_points] = category_ranks.values.sum
    end

    rankings
  end
end
