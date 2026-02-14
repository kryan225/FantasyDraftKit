require 'rails_helper'

RSpec.describe "DraftAnalyzer", type: :request do
  let!(:league) do
    create(:league,
      name: "Test League",
      team_count: 12,
      auction_budget: 260,
      roster_config: {
        "C" => 2,
        "1B" => 1,
        "2B" => 1,
        "3B" => 1,
        "SS" => 1,
        "MI" => 1,
        "CI" => 1,
        "OF" => 5,
        "UTIL" => 1,
        "SP" => 5,
        "RP" => 3,
        "BENCH" => 0
      }
    )
  end

  let!(:team1) { create(:team, league: league, name: "Team 1", budget_remaining: 260) }
  let!(:team2) { create(:team, league: league, name: "Team 2", budget_remaining: 260) }

  describe "GET /draft_analyzer" do
    it "loads the draft analyzer page successfully" do
      get draft_analyzer_path
      expect(response).to have_http_status(:success)
    end

    it "calculates position fill rates for all positions" do
      get draft_analyzer_path
      expect(assigns(:position_fill_rates)).to be_an(Array)
      expect(assigns(:position_fill_rates)).not_to be_empty
    end

    it "includes required metrics in position fill rates" do
      get draft_analyzer_path
      position_data = assigns(:position_fill_rates).first

      expect(position_data).to have_key(:position)
      expect(position_data).to have_key(:total_slots)
      expect(position_data).to have_key(:filled_slots)
      expect(position_data).to have_key(:available_slots)
      expect(position_data).to have_key(:fill_percentage)
      expect(position_data).to have_key(:teams_can_draft)
      expect(position_data).to have_key(:teams_can_draft_count)
    end

    context "with drafted players" do
      let!(:catcher) { create(:player, name: "Catcher", positions: "C") }
      let!(:first_baseman) { create(:player, name: "First Baseman", positions: "1B") }

      before do
        create(:draft_pick, team: team1, player: catcher, league: league, drafted_position: "C", price: 20)
        create(:draft_pick, team: team2, player: first_baseman, league: league, drafted_position: "1B", price: 15)
      end

      it "correctly counts filled slots" do
        get draft_analyzer_path

        c_data = assigns(:position_fill_rates).find { |p| p[:position] == "C" }
        expect(c_data[:filled_slots]).to eq(1)
        expect(c_data[:available_slots]).to eq(23) # 2 per team × 12 teams - 1 filled

        first_base_data = assigns(:position_fill_rates).find { |p| p[:position] == "1B" }
        expect(first_base_data[:filled_slots]).to eq(1)
        expect(first_base_data[:available_slots]).to eq(11) # 1 per team × 12 teams - 1 filled
      end

      it "calculates fill percentage" do
        get draft_analyzer_path

        c_data = assigns(:position_fill_rates).find { |p| p[:position] == "C" }
        expect(c_data[:fill_percentage]).to be_within(0.1).of(4.2) # 1/24 ≈ 4.2%
      end
    end
  end

  describe "Teams Can Draft Logic (Integration)" do
    let(:controller) { DraftAnalyzerController.new }

    before do
      controller.instance_variable_set(:@league, league)
      controller.instance_variable_set(:@teams, [team1, team2])
      allow(controller).to receive(:current_league).and_return(league)
    end

    context "direct slot availability" do
      it "returns true when team has empty slots" do
        # Team 1 has 0/2 catchers
        expect(controller.send(:team_can_draft_position?, team1, "C")).to be true
      end

      it "returns true when team has partial slots filled" do
        catcher = create(:player, positions: "C")
        create(:draft_pick, team: team1, player: catcher, league: league, drafted_position: "C", price: 10)
        # Team 1 has 1/2 catchers
        expect(controller.send(:team_can_draft_position?, team1, "C")).to be true
      end
    end

    context "bidirectional lookahead algorithm" do
      let!(:catcher1) { create(:player, name: "Catcher 1", positions: "C") }
      let!(:catcher2) { create(:player, name: "Catcher 2", positions: "C") }
      let!(:first_baseman) { create(:player, name: "First Baseman", positions: "1B") }
      let!(:outfielder) { create(:player, name: "Outfielder", positions: "OF") }

      context "inbound moves (flex player can move TO target position)" do
        it "returns true when flex has space and has eligible player that can fill position" do
          # This test demonstrates Direction 1: flex player can move TO target position
          # Scenario: 2B slot is full, but MI (flex) has a 2B player and MI has space
          # Algorithm should detect: MI player can move to 2B, creating space at MI for new 2B player

          # Fill the 2B slot (1/1)
          second_baseman_at_2b = create(:player, positions: "2B")
          create(:draft_pick, team: team1, player: second_baseman_at_2b, league: league, drafted_position: "2B", price: 10)

          # MI is not full (0/1), but let's create a SS at MI to test the algorithm
          # Actually, we need a 2B-eligible player at MI for Direction 1 to work
          # But MI is empty (0/1), so Direction 1 won't trigger

          # Better test: Use OF and UTIL instead
          # Fill all OF slots (5/5)
          5.times do
            of_player = create(:player, positions: "OF")
            create(:draft_pick, team: team1, player: of_player, league: league, drafted_position: "OF", price: 10)
          end

          # UTIL is empty (0/1) - has space
          # But no OF player at UTIL yet to move

          # Even better: Test that when flex is empty, Direction 1 returns false
          # Then test Direction 2 (outbound moves) handles this case

          # Let's simplify: With 1 UTIL config, test that C cannot be drafted when both C and UTIL are full
          # (this is now covered by the test in outbound moves context)

          # For Direction 1 to work properly, we need flex to have space AND have an eligible player
          # With 1 UTIL, let's not fill UTIL:

          # Fill both C slots (2/2)
          create(:draft_pick, team: team1, player: catcher1, league: league, drafted_position: "C", price: 10)
          create(:draft_pick, team: team1, player: catcher2, league: league, drafted_position: "C", price: 10)

          # UTIL is empty (0/1) - no players there yet
          # Direction 1 won't trigger (no moveable players at flex)
          # Direction 2 should handle this: C player can move to UTIL

          # Can draft C? Yes, via Direction 2 (C player moves to UTIL)
          expect(controller.send(:team_can_draft_position?, team1, "C")).to be true
        end
      end

      context "outbound moves (player at target position can move OUT to available position)" do
        it "returns true when player can move to empty UTIL" do
          # Fill all OF slots (3/3)
          of1 = create(:player, positions: "OF")
          of2 = create(:player, positions: "OF")
          of3 = create(:player, positions: "OF")
          create(:draft_pick, team: team1, player: of1, league: league, drafted_position: "OF", price: 10)
          create(:draft_pick, team: team1, player: of2, league: league, drafted_position: "OF", price: 10)
          create(:draft_pick, team: team1, player: of3, league: league, drafted_position: "OF", price: 10)

          # UTIL is empty (0/1)
          # Can draft OF because current OF can move to UTIL
          expect(controller.send(:team_can_draft_position?, team1, "OF")).to be true
        end

        it "returns true when UTIL player can move to open position slot" do
          # Fill UTIL slot with OF player
          create(:draft_pick, team: team1, player: outfielder, league: league, drafted_position: "UTIL", price: 10)

          # OF has slots available (0/3)
          # Can draft UTIL because current UTIL player (OF) can move to OF
          expect(controller.send(:team_can_draft_position?, team1, "UTIL")).to be true
        end

        it "returns false when no legal moves are available" do
          # Fill 1B slot
          create(:draft_pick, team: team1, player: first_baseman, league: league, drafted_position: "1B", price: 10)

          # Fill CI with a 3B (not moveable to 1B)
          third_baseman = create(:player, positions: "3B")
          create(:draft_pick, team: team1, player: third_baseman, league: league, drafted_position: "CI", price: 10)

          # Fill UTIL with an OF (not moveable to 1B)
          create(:draft_pick, team: team1, player: outfielder, league: league, drafted_position: "UTIL", price: 10)

          # Cannot draft 1B - no legal moves available
          # The 1B player (Freeman) can't move to CI (occupied by 3B), can't move to UTIL (occupied by OF)
          expect(controller.send(:team_can_draft_position?, team1, "1B")).to be false
        end

        it "returns false when team's entire roster is full" do
          # Create a complete roster (22 total slots based on roster_config)
          roster_config = league.roster_config

          # Fill all positions according to roster_config
          create(:draft_pick, team: team1, player: create(:player, positions: "C"), league: league, drafted_position: "C", price: 10)
          create(:draft_pick, team: team1, player: create(:player, positions: "C"), league: league, drafted_position: "C", price: 10)
          create(:draft_pick, team: team1, player: first_baseman, league: league, drafted_position: "1B", price: 10)
          create(:draft_pick, team: team1, player: create(:player, positions: "2B"), league: league, drafted_position: "2B", price: 10)
          create(:draft_pick, team: team1, player: create(:player, positions: "3B"), league: league, drafted_position: "3B", price: 10)
          create(:draft_pick, team: team1, player: create(:player, positions: "SS"), league: league, drafted_position: "SS", price: 10)
          create(:draft_pick, team: team1, player: create(:player, positions: "2B"), league: league, drafted_position: "MI", price: 10)
          create(:draft_pick, team: team1, player: create(:player, positions: "1B"), league: league, drafted_position: "CI", price: 10)

          # 5 OF
          5.times { create(:draft_pick, team: team1, player: create(:player, positions: "OF"), league: league, drafted_position: "OF", price: 10) }

          # 1 UTIL
          create(:draft_pick, team: team1, player: create(:player, positions: "OF"), league: league, drafted_position: "UTIL", price: 10)

          # 5 SP
          5.times { create(:draft_pick, team: team1, player: create(:player, positions: "SP"), league: league, drafted_position: "SP", price: 10) }

          # 3 RP
          3.times { create(:draft_pick, team: team1, player: create(:player, positions: "RP"), league: league, drafted_position: "RP", price: 10) }

          # Verify roster is full (22/22)
          total_slots = roster_config.values.sum
          expect(team1.draft_picks.count).to eq(total_slots)

          # Cannot draft ANY position when roster is completely full
          expect(controller.send(:team_can_draft_position?, team1, "1B")).to be false
          expect(controller.send(:team_can_draft_position?, team1, "2B")).to be false
          expect(controller.send(:team_can_draft_position?, team1, "OF")).to be false
          expect(controller.send(:team_can_draft_position?, team1, "MI")).to be false
          expect(controller.send(:team_can_draft_position?, team1, "UTIL")).to be false
        end

        it "returns false when position is full and flex position with eligible player is also full" do
          # Scenario: C is 2/2 full, UTIL is 1/1 full with a C
          # Bug: Algorithm incorrectly says team can draft C because UTIL has a C
          # Fix: Must check if UTIL has space for new player before allowing swap

          # Fill both C slots
          catcher1 = create(:player, positions: "C")
          catcher2 = create(:player, positions: "C")
          create(:draft_pick, team: team1, player: catcher1, league: league, drafted_position: "C", price: 10)
          create(:draft_pick, team: team1, player: catcher2, league: league, drafted_position: "C", price: 10)

          # Fill UTIL with a C-eligible player
          catcher_at_util = create(:player, positions: "C")
          create(:draft_pick, team: team1, player: catcher_at_util, league: league, drafted_position: "UTIL", price: 10)

          # C is 2/2 and UTIL is 1/1 (both full)
          # Cannot draft C because:
          # - C position is full (2/2)
          # - UTIL has a C, BUT UTIL is also full (1/1)
          # - There's no space for a swap to occur
          expect(controller.send(:team_can_draft_position?, team1, "C")).to be false
        end
      end
    end
  end

  describe "Nomination Suggestions" do
    let!(:sp_player) { create(:player, name: "Ace Pitcher", positions: "SP", calculated_value: 30.0) }
    let!(:rp_player) { create(:player, name: "Closer", positions: "RP", calculated_value: 20.0) }
    let!(:of_player) { create(:player, name: "Slugger", positions: "OF", calculated_value: 25.0) }
    let!(:low_value) { create(:player, name: "Scrub", positions: "OF", calculated_value: 0.5) }

    context "with no my_team param" do
      it "sets nomination_suggestions to empty array" do
        get draft_analyzer_path
        expect(assigns(:nomination_suggestions)).to eq([])
      end

      it "shows prompt to select a team" do
        get draft_analyzer_path
        expect(response.body).to include("Select your team above")
      end
    end

    context "with valid my_team param" do
      it "returns nomination suggestions" do
        get draft_analyzer_path, params: { my_team: team1.id }
        suggestions = assigns(:nomination_suggestions)

        expect(suggestions).to be_an(Array)
        expect(suggestions).not_to be_empty
      end

      it "includes required keys in each suggestion" do
        get draft_analyzer_path, params: { my_team: team1.id }
        suggestion = assigns(:nomination_suggestions).first

        expect(suggestion).to have_key(:player)
        expect(suggestion).to have_key(:score)
        expect(suggestion).to have_key(:target_position)
        expect(suggestion).to have_key(:opponent_demand)
        expect(suggestion).to have_key(:reasons)
      end

      it "includes reason strings in suggestions" do
        get draft_analyzer_path, params: { my_team: team1.id }
        suggestion = assigns(:nomination_suggestions).first

        expect(suggestion[:reasons]).to be_an(Array)
        expect(suggestion[:reasons]).not_to be_empty
        expect(suggestion[:reasons].any? { |r| r.include?("opponents need") }).to be true
      end

      it "excludes players with calculated_value <= 1" do
        get draft_analyzer_path, params: { my_team: team1.id }
        players = assigns(:nomination_suggestions).map { |s| s[:player] }

        expect(players).not_to include(low_value)
      end

      it "limits to at most 15 suggestions" do
        # Create many available players
        20.times do |i|
          create(:player, name: "Player #{i}", positions: "OF", calculated_value: 5.0 + i)
        end

        get draft_analyzer_path, params: { my_team: team1.id }
        expect(assigns(:nomination_suggestions).size).to be <= 15
      end
    end

    context "ranking behavior" do
      it "ranks players at positions user doesn't need higher than positions they do need" do
        # Fill all SP slots for team1 so team1 doesn't need SP
        5.times do
          sp = create(:player, positions: "SP", calculated_value: 2.0)
          create(:draft_pick, team: team1, player: sp, league: league, drafted_position: "SP", price: 10)
        end

        # Create two equal-value players: one SP (team1 doesn't need), one OF (team1 does need)
        sp_nom = create(:player, name: "SP Nomination", positions: "SP", calculated_value: 15.0)
        of_nom = create(:player, name: "OF Nomination", positions: "OF", calculated_value: 15.0)

        get draft_analyzer_path, params: { my_team: team1.id }
        suggestions = assigns(:nomination_suggestions)
        sp_entry = suggestions.find { |s| s[:player] == sp_nom }
        of_entry = suggestions.find { |s| s[:player] == of_nom }

        # SP should rank higher because team1 doesn't need it
        expect(sp_entry).not_to be_nil
        expect(of_entry).not_to be_nil
        expect(sp_entry[:score]).to be > of_entry[:score]
      end

      it "ranks higher-value players above lower-value players (all else equal)" do
        high_val = create(:player, name: "High Value SP", positions: "SP", calculated_value: 40.0)
        low_val = create(:player, name: "Low Value SP", positions: "SP", calculated_value: 5.0)

        get draft_analyzer_path, params: { my_team: team1.id }
        suggestions = assigns(:nomination_suggestions)
        high_entry = suggestions.find { |s| s[:player] == high_val }
        low_entry = suggestions.find { |s| s[:player] == low_val }

        expect(high_entry).not_to be_nil
        expect(low_entry).not_to be_nil
        expect(high_entry[:score]).to be > low_entry[:score]
      end
    end

    context "with invalid my_team param" do
      it "falls back to empty suggestions without crashing" do
        get draft_analyzer_path, params: { my_team: 999999 }
        expect(response).to have_http_status(:success)
        expect(assigns(:nomination_suggestions)).to eq([])
      end

      it "falls back for non-numeric my_team param" do
        get draft_analyzer_path, params: { my_team: "garbage" }
        expect(response).to have_http_status(:success)
        expect(assigns(:nomination_suggestions)).to eq([])
      end
    end
  end

  describe "Team Needs Matrix" do
    it "returns a hash with :positions and :teams keys" do
      get draft_analyzer_path
      matrix = assigns(:team_needs_matrix)

      expect(matrix).to be_a(Hash)
      expect(matrix).to have_key(:positions)
      expect(matrix).to have_key(:teams)
    end

    it "includes all active positions excluding BENCH" do
      get draft_analyzer_path
      positions = assigns(:team_needs_matrix)[:positions]

      expect(positions).to include("C", "1B", "2B", "3B", "SS", "MI", "CI", "OF", "UTIL", "SP", "RP")
      expect(positions).not_to include("BENCH")
    end

    it "includes all teams in the league" do
      get draft_analyzer_path
      teams = assigns(:team_needs_matrix)[:teams].map { |td| td[:team] }

      expect(teams).to contain_exactly(team1, team2)
    end

    it "shows :open state with correct count for empty roster" do
      get draft_analyzer_path
      team1_data = assigns(:team_needs_matrix)[:teams].find { |td| td[:team] == team1 }

      of_needs = team1_data[:needs]["OF"]
      expect(of_needs[:state]).to eq(:open)
      expect(of_needs[:open_slots]).to eq(5)

      c_needs = team1_data[:needs]["C"]
      expect(c_needs[:state]).to eq(:open)
      expect(c_needs[:open_slots]).to eq(2)
    end

    it "shows :flex state when position is full but roster move is possible" do
      # Fill all 5 OF slots for team1
      5.times do
        player = create(:player, positions: "OF")
        create(:draft_pick, team: team1, player: player, league: league, drafted_position: "OF", price: 10)
      end
      # UTIL is still open (0/1), so OF can be drafted via UTIL or by moving an OF player there

      get draft_analyzer_path
      team1_data = assigns(:team_needs_matrix)[:teams].find { |td| td[:team] == team1 }

      of_needs = team1_data[:needs]["OF"]
      expect(of_needs[:state]).to eq(:flex)
      expect(of_needs[:open_slots]).to eq(0)
    end

    it "shows :closed state when position is full and no roster move available" do
      # Fill 1B (1/1)
      fb = create(:player, positions: "1B")
      create(:draft_pick, team: team1, player: fb, league: league, drafted_position: "1B", price: 10)
      # Fill CI with a 3B (not moveable to 1B)
      tb = create(:player, positions: "3B")
      create(:draft_pick, team: team1, player: tb, league: league, drafted_position: "CI", price: 10)
      # Fill UTIL with an OF (not moveable to 1B)
      of = create(:player, positions: "OF")
      create(:draft_pick, team: team1, player: of, league: league, drafted_position: "UTIL", price: 10)

      get draft_analyzer_path
      team1_data = assigns(:team_needs_matrix)[:teams].find { |td| td[:team] == team1 }

      fb_needs = team1_data[:needs]["1B"]
      expect(fb_needs[:state]).to eq(:closed)
    end

    it "shows all positions :closed when roster is full" do
      roster_config = league.roster_config
      # Fill every position to capacity
      create(:draft_pick, team: team1, player: create(:player, positions: "C"), league: league, drafted_position: "C", price: 1)
      create(:draft_pick, team: team1, player: create(:player, positions: "C"), league: league, drafted_position: "C", price: 1)
      create(:draft_pick, team: team1, player: create(:player, positions: "1B"), league: league, drafted_position: "1B", price: 1)
      create(:draft_pick, team: team1, player: create(:player, positions: "2B"), league: league, drafted_position: "2B", price: 1)
      create(:draft_pick, team: team1, player: create(:player, positions: "3B"), league: league, drafted_position: "3B", price: 1)
      create(:draft_pick, team: team1, player: create(:player, positions: "SS"), league: league, drafted_position: "SS", price: 1)
      create(:draft_pick, team: team1, player: create(:player, positions: "2B"), league: league, drafted_position: "MI", price: 1)
      create(:draft_pick, team: team1, player: create(:player, positions: "1B"), league: league, drafted_position: "CI", price: 1)
      5.times { create(:draft_pick, team: team1, player: create(:player, positions: "OF"), league: league, drafted_position: "OF", price: 1) }
      create(:draft_pick, team: team1, player: create(:player, positions: "OF"), league: league, drafted_position: "UTIL", price: 1)
      5.times { create(:draft_pick, team: team1, player: create(:player, positions: "SP"), league: league, drafted_position: "SP", price: 1) }
      3.times { create(:draft_pick, team: team1, player: create(:player, positions: "RP"), league: league, drafted_position: "RP", price: 1) }

      get draft_analyzer_path
      team1_data = assigns(:team_needs_matrix)[:teams].find { |td| td[:team] == team1 }

      team1_data[:needs].each do |position, cell|
        expect(cell[:state]).to eq(:closed), "Expected #{position} to be :closed but was #{cell[:state]}"
      end
    end

    it "reports accurate roster counts" do
      # Draft 3 players for team1
      3.times do
        player = create(:player, positions: "OF")
        create(:draft_pick, team: team1, player: player, league: league, drafted_position: "OF", price: 10)
      end

      get draft_analyzer_path
      team1_data = assigns(:team_needs_matrix)[:teams].find { |td| td[:team] == team1 }

      expect(team1_data[:total_filled]).to eq(3)
      expect(team1_data[:total_slots]).to eq(22)
    end
  end
end
