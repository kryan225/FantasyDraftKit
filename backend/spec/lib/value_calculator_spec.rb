# frozen_string_literal: true

require 'rails_helper'

RSpec.describe ValueCalculator do
  # Create a test class that includes the concern
  let(:test_class) { Class.new { include ValueCalculator } }
  let(:subject) { test_class.new }

  let(:league) do
    create(:league,
           team_count: 12,
           auction_budget: 260,
           roster_config: {
             'C' => 2, '1B' => 1, '2B' => 1, '3B' => 1, 'SS' => 1,
             'MI' => 1, 'CI' => 1, 'OF' => 5, 'UTIL' => 1,
             'SP' => 5, 'RP' => 3, 'BENCH' => 0
           })
  end

  # =============================================================================
  # 1. Statistical Functions (10 tests)
  # =============================================================================

  describe '#calculate_mean' do
    it 'calculates mean of positive numbers' do
      result = subject.send(:calculate_mean, [10, 20, 30, 40, 50])
      expect(result).to eq(30.0)
    end

    it 'handles empty array' do
      result = subject.send(:calculate_mean, [])
      expect(result).to eq(0.0)
    end

    it 'handles single value' do
      result = subject.send(:calculate_mean, [42])
      expect(result).to eq(42.0)
    end
  end

  describe '#calculate_stddev' do
    it 'calculates standard deviation' do
      values = [2, 4, 4, 4, 5, 5, 7, 9]
      mean = 5.0
      result = subject.send(:calculate_stddev, values, mean)
      expect(result).to be_within(0.01).of(2.0)
    end

    it 'handles identical values (stddev = 0)' do
      values = [5, 5, 5, 5]
      mean = 5.0
      result = subject.send(:calculate_stddev, values, mean)
      expect(result).to eq(0.0)
    end

    it 'handles single value' do
      result = subject.send(:calculate_stddev, [42], 42.0)
      expect(result).to eq(0.0)
    end
  end

  describe '#calculate_weighted_mean' do
    it 'calculates weighted average correctly' do
      # Batting average: 3 players with 100, 200, 300 AB
      values = [0.300, 0.250, 0.280]
      weights = [100, 200, 300]
      # Expected: (0.300*100 + 0.250*200 + 0.280*300) / 600 = 164/600 = 0.2733
      result = subject.send(:calculate_weighted_mean, values, weights)
      expect(result).to be_within(0.001).of(0.2733)
    end

    it 'handles empty arrays' do
      result = subject.send(:calculate_weighted_mean, [], [])
      expect(result).to eq(0.0)
    end

    it 'handles zero total weight' do
      result = subject.send(:calculate_weighted_mean, [0.300], [0])
      expect(result).to eq(0.0)
    end
  end

  describe '#calculate_weighted_variance' do
    it 'calculates weighted variance correctly' do
      values = [0.300, 0.250, 0.280]
      weights = [100, 200, 300]
      mean = 0.2733
      result = subject.send(:calculate_weighted_variance, values, weights, mean)
      expect(result).to be > 0
    end
  end

  # =============================================================================
  # 2. Helper Methods
  # =============================================================================

  describe '#hitter?' do
    it 'identifies hitters by position' do
      player = create(:player, positions: 'OF')
      expect(subject.send(:hitter?, player)).to be true
    end

    it 'identifies multi-position hitters with slash delimiter' do
      player = create(:player, positions: '2B/SS')
      expect(subject.send(:hitter?, player)).to be true
    end

    it 'identifies multi-position hitters with comma delimiter' do
      player = create(:player, positions: '2B,SS')
      expect(subject.send(:hitter?, player)).to be true
    end

    it 'rejects pitchers' do
      player = create(:player, positions: 'SP')
      expect(subject.send(:hitter?, player)).to be false
    end
  end

  describe '#pitcher?' do
    it 'identifies starting pitchers' do
      player = create(:player, positions: 'SP')
      expect(subject.send(:pitcher?, player)).to be true
    end

    it 'identifies relief pitchers' do
      player = create(:player, positions: 'RP')
      expect(subject.send(:pitcher?, player)).to be true
    end

    it 'rejects hitters' do
      player = create(:player, positions: 'OF')
      expect(subject.send(:pitcher?, player)).to be false
    end
  end

  describe '#skip_player?' do
    it 'skips player with no projections' do
      player = create(:player, positions: 'OF', projections: nil)
      expect(subject.send(:skip_player?, player)).to be true
    end

    it 'skips player with empty projections' do
      player = create(:player, positions: 'OF', projections: {})
      expect(subject.send(:skip_player?, player)).to be true
    end

    it 'skips hitter with zero at_bats' do
      player = create(:player, positions: 'OF',
                               projections: { 'home_runs' => 20, 'runs' => 75, 'rbi' => 80, 'stolen_bases' => 10, 'batting_average' => 0.270, 'at_bats' => 0 })
      expect(subject.send(:skip_player?, player)).to be true
    end

    it 'skips pitcher with zero innings_pitched' do
      player = create(:player, positions: 'SP',
                               projections: { 'wins' => 10, 'saves' => 0, 'strikeouts' => 150, 'era' => 4.00, 'whip' => 1.25, 'innings_pitched' => 0 })
      expect(subject.send(:skip_player?, player)).to be true
    end

    it 'skips hitter with all zero counting stats' do
      player = create(:player, positions: 'OF',
                               projections: { 'home_runs' => 0, 'runs' => 0, 'rbi' => 0, 'stolen_bases' => 0, 'batting_average' => 0.000, 'at_bats' => 500 })
      expect(subject.send(:skip_player?, player)).to be true
    end

    it 'does not skip valid hitter' do
      player = create(:player, positions: 'OF',
                               projections: { 'home_runs' => 20, 'runs' => 75, 'rbi' => 80, 'stolen_bases' => 10, 'batting_average' => 0.270, 'at_bats' => 550 })
      expect(subject.send(:skip_player?, player)).to be false
    end

    it 'does not skip valid pitcher' do
      player = create(:player, positions: 'SP',
                               projections: { 'wins' => 12, 'saves' => 0, 'strikeouts' => 175, 'era' => 3.75, 'whip' => 1.22, 'innings_pitched' => 185 })
      expect(subject.send(:skip_player?, player)).to be false
    end
  end

  # =============================================================================
  # 3. Integration Tests (Full Calculation)
  # =============================================================================

  describe '#recalculate_values' do
    # Clean up before each test in this block to avoid interference
    before(:each) do
      Player.destroy_all
    end

    let!(:elite_hitter) do
      create(:player, positions: 'OF',
                      projections: { 'home_runs' => 45, 'runs' => 110, 'rbi' => 115, 'stolen_bases' => 25, 'batting_average' => 0.310, 'at_bats' => 620 })
    end

    let!(:average_hitter) do
      create(:player, positions: '2B',
                      projections: { 'home_runs' => 18, 'runs' => 75, 'rbi' => 70, 'stolen_bases' => 8, 'batting_average' => 0.270, 'at_bats' => 530 })
    end

    let!(:elite_pitcher) do
      create(:player, positions: 'SP',
                      projections: { 'wins' => 15, 'saves' => 0, 'strikeouts' => 220, 'era' => 2.80, 'whip' => 1.05, 'innings_pitched' => 200 })
    end

    let!(:average_pitcher) do
      create(:player, positions: 'RP',
                      projections: { 'wins' => 4, 'saves' => 35, 'strikeouts' => 75, 'era' => 3.20, 'whip' => 1.15, 'innings_pitched' => 70 })
    end

    # Create replacement-level players to establish baseline
    let!(:replacement_hitters) do
      Array.new(50) do |i|
        create(:player, positions: 'OF',
                        projections: { 'home_runs' => 15 - (i * 0.2).to_i, 'runs' => 65 - (i * 0.5).to_i, 'rbi' => 60 - (i * 0.5).to_i,
                                       'stolen_bases' => 5, 'batting_average' => 0.260, 'at_bats' => 500 })
      end
    end

    let!(:replacement_pitchers) do
      Array.new(30) do |i|
        create(:player, positions: 'SP',
                        projections: { 'wins' => 10 - (i * 0.2).to_i, 'saves' => 0, 'strikeouts' => 150 - (i * 2).to_i,
                                       'era' => 4.00 + (i * 0.05), 'whip' => 1.30 + (i * 0.01), 'innings_pitched' => 170 })
      end
    end

    it 'calculates values for all available players' do
      result = subject.recalculate_values(league)

      total_players = 2 + 2 + 50 + 30 # elite + average + replacement
      expect(result[:count]).to eq(total_players)
    end

    it 'assigns highest value to elite player' do
      subject.recalculate_values(league)

      elite_hitter.reload
      average_hitter.reload

      expect(elite_hitter.calculated_value).to be > average_hitter.calculated_value
      expect(elite_hitter.calculated_value).to be > 1.0
    end

    it 'enforces $1 minimum for all players' do
      subject.recalculate_values(league)

      all_values = Player.where(is_drafted: false).pluck(:calculated_value)
      expect(all_values).to all(be >= 1.0)
    end

    it 'returns summary statistics' do
      result = subject.recalculate_values(league)

      expect(result).to have_key(:count)
      expect(result).to have_key(:min_value)
      expect(result).to have_key(:max_value)
      expect(result).to have_key(:avg_value)

      expect(result[:min_value]).to eq(1.0)
      expect(result[:max_value]).to be > result[:avg_value]
      expect(result[:avg_value]).to be > result[:min_value]
    end

    it 'handles empty player pool gracefully' do
      Player.destroy_all
      result = subject.recalculate_values(league)

      expect(result[:count]).to eq(0)
      expect(result[:min_value]).to eq(0)
      expect(result[:max_value]).to eq(0)
      expect(result[:avg_value]).to eq(0)
    end

    it 'skips drafted players' do
      # Verify initial state
      initial_count = Player.where(is_drafted: false).count
      expect(elite_hitter.is_drafted).to be false

      # Mark as drafted by assigning to a team (Player model syncs is_drafted with team_id)
      team = create(:team, league: league)
      elite_hitter.update!(team: team)
      elite_hitter.reload
      expect(elite_hitter.is_drafted).to be true

      result = subject.recalculate_values(league)

      # Result should have one fewer player than before
      expect(result[:count]).to eq(initial_count - 1)
      expect(Player.where(is_drafted: true).count).to eq(1)
    end

    it 'updates player calculated_value field' do
      expect { subject.recalculate_values(league) }
        .to change { elite_hitter.reload.calculated_value }.from(9.99).to be > 1.0
    end

    it 'conserves total budget (within 10%)' do
      subject.recalculate_values(league)

      total_value = Player.where(is_drafted: false).sum(:calculated_value)
      expected_budget = league.team_count * league.auction_budget

      # Should be close to total budget (within 10% due to $1 floor and rounding)
      expect(total_value).to be_within(expected_budget * 0.10).of(expected_budget)
    end

    it 'handles players with missing projections' do
      # Create player with incomplete projections
      incomplete = create(:player, positions: 'OF', projections: { 'home_runs' => 20 })

      result = subject.recalculate_values(league)

      # Should skip incomplete player
      incomplete.reload
      expect(incomplete.calculated_value).to eq(9.99) # Unchanged from factory default
    end

    it 'handles players with zero volume stats' do
      zero_ab = create(:player, positions: 'OF',
                                projections: { 'home_runs' => 0, 'runs' => 0, 'rbi' => 0, 'stolen_bases' => 0, 'batting_average' => 0.000, 'at_bats' => 0 })

      result = subject.recalculate_values(league)

      # Should skip zero at_bats player
      zero_ab.reload
      expect(zero_ab.calculated_value).to eq(9.99) # Unchanged
    end

    it 'handles mixed position eligibility correctly' do
      # Create multi-position player
      multi = create(:player, positions: 'C/1B',
                              projections: { 'home_runs' => 25, 'runs' => 85, 'rbi' => 90, 'stolen_bases' => 3, 'batting_average' => 0.280, 'at_bats' => 550 })

      subject.recalculate_values(league)

      multi.reload
      # Multi-position player should get value (using best replacement level)
      expect(multi.calculated_value).to be >= 1.0
    end

    it 'separates hitters and pitchers correctly' do
      subject.recalculate_values(league)

      # Verify both hitters and pitchers got values
      elite_hitter.reload
      elite_pitcher.reload

      expect(elite_hitter.calculated_value).to be > 1.0
      expect(elite_pitcher.calculated_value).to be > 1.0
    end
  end

  # =============================================================================
  # 4. Edge Cases
  # =============================================================================

  describe 'edge cases' do
    it 'handles all identical stats (stddev = 0)' do
      identical_players = Array.new(10) do
        create(:player, positions: 'OF',
                        projections: { 'home_runs' => 25, 'runs' => 80, 'rbi' => 85, 'stolen_bases' => 10, 'batting_average' => 0.275, 'at_bats' => 550 })
      end

      result = subject.recalculate_values(league)

      # All should get $1 (no differentiation possible)
      values = identical_players.map { |p| p.reload.calculated_value }
      expect(values).to all(eq(1.0))
    end

    it 'handles single player in pool' do
      Player.destroy_all
      solo_player = create(:player, positions: 'OF',
                                    projections: { 'home_runs' => 30, 'runs' => 90, 'rbi' => 95, 'stolen_bases' => 15, 'batting_average' => 0.285, 'at_bats' => 570 })

      result = subject.recalculate_values(league)

      expect(result[:count]).to eq(1)
      solo_player.reload
      # Single player with no variance gets exactly $1 (no other players to compare against)
      expect(solo_player.calculated_value).to eq(1.0)
    end

    it 'handles only hitters (no pitchers)' do
      Player.destroy_all
      hitters = Array.new(5) do |i|
        create(:player, positions: 'OF',
                        projections: { 'home_runs' => 25 - i * 3, 'runs' => 85 - i * 5, 'rbi' => 80 - i * 5, 'stolen_bases' => 10, 'batting_average' => 0.275, 'at_bats' => 550 })
      end

      result = subject.recalculate_values(league)

      expect(result[:count]).to eq(5)
      hitters.each do |h|
        h.reload
        expect(h.calculated_value).to be >= 1.0
      end
    end

    it 'handles only pitchers (no hitters)' do
      Player.destroy_all
      pitchers = Array.new(5) do |i|
        create(:player, positions: 'SP',
                        projections: { 'wins' => 12 - i, 'saves' => 0, 'strikeouts' => 180 - i * 10, 'era' => 3.50 + i * 0.2, 'whip' => 1.20 + i * 0.05, 'innings_pitched' => 180 })
      end

      result = subject.recalculate_values(league)

      expect(result[:count]).to eq(5)
      pitchers.each do |p|
        p.reload
        expect(p.calculated_value).to be >= 1.0
      end
    end

    it 'handles extreme outlier player' do
      # Create normal players
      normals = Array.new(20) do
        create(:player, positions: 'OF',
                        projections: { 'home_runs' => 20, 'runs' => 75, 'rbi' => 75, 'stolen_bases' => 8, 'batting_average' => 0.270, 'at_bats' => 530 })
      end

      # Create extreme outlier (Ohtani-level)
      outlier = create(:player, positions: 'OF',
                                projections: { 'home_runs' => 60, 'runs' => 130, 'rbi' => 135, 'stolen_bases' => 30, 'batting_average' => 0.330, 'at_bats' => 650 })

      subject.recalculate_values(league)

      outlier.reload
      normals.first.reload

      # Outlier should be worth significantly more
      expect(outlier.calculated_value).to be > normals.first.calculated_value * 1.5
    end

    it 'handles very large player pool (performance test)' do
      Player.destroy_all

      # Create 200 players
      large_pool = Array.new(200) do |i|
        position = ['OF', '1B', '2B', 'SS', 'C'].sample
        create(:player, positions: position,
                        projections: {
                          'home_runs' => rand(10..40), 'runs' => rand(60..110), 'rbi' => rand(55..115),
                          'stolen_bases' => rand(0..30), 'batting_average' => (0.240 + rand(0..70) / 1000.0).round(3), 'at_bats' => rand(450..650)
                        })
      end

      start_time = Time.now
      result = subject.recalculate_values(league)
      elapsed = Time.now - start_time

      expect(result[:count]).to eq(200)
      expect(elapsed).to be < 5.0 # Should be fast (< 5 seconds)
    end

    it 'handles custom roster configuration' do
      custom_league = create(:league,
                             team_count: 10,
                             auction_budget: 300,
                             roster_config: {
                               'C' => 1, '1B' => 1, '2B' => 1, '3B' => 1, 'SS' => 1, 'OF' => 4,
                               'SP' => 6, 'RP' => 2
                             })

      Player.destroy_all

      players = Array.new(30) do |i|
        position = i < 15 ? 'OF' : 'SP'
        if position == 'OF'
          create(:player, positions: position,
                          projections: { 'home_runs' => 20 + i, 'runs' => 75 + i, 'rbi' => 75 + i, 'stolen_bases' => 8, 'batting_average' => 0.270, 'at_bats' => 530 })
        else
          create(:player, positions: position,
                          projections: { 'wins' => 10 + i - 15, 'saves' => 0, 'strikeouts' => 160 + (i - 15) * 5, 'era' => 3.80, 'whip' => 1.25, 'innings_pitched' => 175 })
        end
      end

      result = subject.recalculate_values(custom_league)

      expect(result[:count]).to eq(30)
      # Total budget should be conserved (within 10%)
      total_value = Player.sum(:calculated_value)
      expected = custom_league.team_count * custom_league.auction_budget
      expect(total_value).to be_within(expected * 0.10).of(expected)
    end
  end

  # =============================================================================
  # 5. Roster Slot Calculation
  # =============================================================================

  describe '#calculate_roster_slots' do
    it 'calculates hitter slots correctly' do
      # C(2) + 1B(1) + 2B(1) + 3B(1) + SS(1) + MI(1) + CI(1) + OF(5) + UTIL(1) = 14
      slots = subject.send(:calculate_roster_slots, league, true)
      expect(slots).to eq(14)
    end

    it 'calculates pitcher slots correctly' do
      # SP(5) + RP(3) = 8
      slots = subject.send(:calculate_roster_slots, league, false)
      expect(slots).to eq(8)
    end

    it 'handles custom roster config' do
      custom_league = create(:league, roster_config: { 'C' => 1, '1B' => 1, 'OF' => 3, 'SP' => 4, 'RP' => 2 })

      hitter_slots = subject.send(:calculate_roster_slots, custom_league, true)
      pitcher_slots = subject.send(:calculate_roster_slots, custom_league, false)

      expect(hitter_slots).to eq(5)  # C(1) + 1B(1) + OF(3)
      expect(pitcher_slots).to eq(6) # SP(4) + RP(2)
    end
  end
end
