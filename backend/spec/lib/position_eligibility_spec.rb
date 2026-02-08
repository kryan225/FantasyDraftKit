require 'rails_helper'

RSpec.describe PositionEligibility do
  # Create a test class that includes the concern
  let(:test_class) do
    Class.new do
      include PositionEligibility
    end
  end

  let(:subject) { test_class.new }

  describe "player eligibility for positions" do
    context "UTIL (Utility) position" do
      it "accepts catchers" do
        player = create(:player, positions: "C")
        expect(subject.player_eligible_for_position?(player, "UTIL")).to be true
      end

      it "accepts first basemen" do
        player = create(:player, positions: "1B")
        expect(subject.player_eligible_for_position?(player, "UTIL")).to be true
      end

      it "accepts second basemen" do
        player = create(:player, positions: "2B")
        expect(subject.player_eligible_for_position?(player, "UTIL")).to be true
      end

      it "accepts third basemen" do
        player = create(:player, positions: "3B")
        expect(subject.player_eligible_for_position?(player, "UTIL")).to be true
      end

      it "accepts shortstops" do
        player = create(:player, positions: "SS")
        expect(subject.player_eligible_for_position?(player, "UTIL")).to be true
      end

      it "accepts outfielders" do
        player = create(:player, positions: "OF")
        expect(subject.player_eligible_for_position?(player, "UTIL")).to be true
      end

      it "accepts multi-position batters" do
        player = create(:player, positions: "2B,SS")
        expect(subject.player_eligible_for_position?(player, "UTIL")).to be true
      end

      it "rejects starting pitchers" do
        player = create(:player, positions: "SP")
        expect(subject.player_eligible_for_position?(player, "UTIL")).to be false
      end

      it "rejects relief pitchers" do
        player = create(:player, positions: "RP")
        expect(subject.player_eligible_for_position?(player, "UTIL")).to be false
      end
    end

    context "MI (Middle Infield) position" do
      it "accepts second basemen" do
        player = create(:player, positions: "2B")
        expect(subject.player_eligible_for_position?(player, "MI")).to be true
      end

      it "accepts shortstops" do
        player = create(:player, positions: "SS")
        expect(subject.player_eligible_for_position?(player, "MI")).to be true
      end

      it "accepts 2B/SS dual position" do
        player = create(:player, positions: "2B,SS")
        expect(subject.player_eligible_for_position?(player, "MI")).to be true
      end

      it "rejects catchers" do
        player = create(:player, positions: "C")
        expect(subject.player_eligible_for_position?(player, "MI")).to be false
      end

      it "rejects first basemen" do
        player = create(:player, positions: "1B")
        expect(subject.player_eligible_for_position?(player, "MI")).to be false
      end

      it "rejects third basemen" do
        player = create(:player, positions: "3B")
        expect(subject.player_eligible_for_position?(player, "MI")).to be false
      end

      it "rejects outfielders" do
        player = create(:player, positions: "OF")
        expect(subject.player_eligible_for_position?(player, "MI")).to be false
      end
    end

    context "CI (Corner Infield) position" do
      it "accepts first basemen" do
        player = create(:player, positions: "1B")
        expect(subject.player_eligible_for_position?(player, "CI")).to be true
      end

      it "accepts third basemen" do
        player = create(:player, positions: "3B")
        expect(subject.player_eligible_for_position?(player, "CI")).to be true
      end

      it "accepts 1B/3B dual position" do
        player = create(:player, positions: "1B,3B")
        expect(subject.player_eligible_for_position?(player, "CI")).to be true
      end

      it "rejects catchers" do
        player = create(:player, positions: "C")
        expect(subject.player_eligible_for_position?(player, "CI")).to be false
      end

      it "rejects second basemen" do
        player = create(:player, positions: "2B")
        expect(subject.player_eligible_for_position?(player, "CI")).to be false
      end

      it "rejects shortstops" do
        player = create(:player, positions: "SS")
        expect(subject.player_eligible_for_position?(player, "CI")).to be false
      end

      it "rejects outfielders" do
        player = create(:player, positions: "OF")
        expect(subject.player_eligible_for_position?(player, "CI")).to be false
      end
    end

    context "Standard positions (direct match)" do
      it "accepts direct position match for C" do
        player = create(:player, positions: "C")
        expect(subject.player_eligible_for_position?(player, "C")).to be true
      end

      it "accepts multi-position player for any listed position" do
        player = create(:player, positions: "2B,SS,OF")
        expect(subject.player_eligible_for_position?(player, "2B")).to be true
        expect(subject.player_eligible_for_position?(player, "SS")).to be true
        expect(subject.player_eligible_for_position?(player, "OF")).to be true
        expect(subject.player_eligible_for_position?(player, "C")).to be false
      end

      it "handles positions with spaces after commas" do
        player = create(:player, positions: "2B, SS, OF")
        expect(subject.player_eligible_for_position?(player, "2B")).to be true
        expect(subject.player_eligible_for_position?(player, "SS")).to be true
      end
    end

    context "BENCH position" do
      it "accepts any batter" do
        player = create(:player, positions: "OF")
        expect(subject.player_eligible_for_position?(player, "BENCH")).to be true
      end

      it "accepts any pitcher" do
        player = create(:player, positions: "SP")
        expect(subject.player_eligible_for_position?(player, "BENCH")).to be true
      end
    end
  end

  describe "flex position relationships" do
    it "returns UTIL, MI, CI as flex options for batter positions" do
      expect(subject.get_flex_positions_for("C")).to eq(["UTIL", "MI", "CI"])
      expect(subject.get_flex_positions_for("1B")).to eq(["UTIL", "MI", "CI"])
      expect(subject.get_flex_positions_for("2B")).to eq(["UTIL", "MI", "CI"])
      expect(subject.get_flex_positions_for("3B")).to eq(["UTIL", "MI", "CI"])
      expect(subject.get_flex_positions_for("SS")).to eq(["UTIL", "MI", "CI"])
      expect(subject.get_flex_positions_for("OF")).to eq(["UTIL", "MI", "CI"])
    end

    it "returns UTIL as flex option for MI" do
      expect(subject.get_flex_positions_for("MI")).to eq(["UTIL"])
    end

    it "returns UTIL as flex option for CI" do
      expect(subject.get_flex_positions_for("CI")).to eq(["UTIL"])
    end

    it "returns empty array for pitcher positions" do
      expect(subject.get_flex_positions_for("SP")).to eq([])
      expect(subject.get_flex_positions_for("RP")).to eq([])
    end

    it "returns empty array for bench" do
      expect(subject.get_flex_positions_for("BENCH")).to eq([])
    end
  end

  describe "eligible positions for a player" do
    it "includes natural positions plus eligible flex positions for a catcher" do
      player = create(:player, positions: "C")
      eligible = subject.eligible_positions_for(player)

      expect(eligible).to include("C")      # Natural position
      expect(eligible).to include("UTIL")   # Batter can go to UTIL
      expect(eligible).to include("BENCH")  # Anyone can go to bench
      expect(eligible).not_to include("MI") # Catcher can't go to MI
      expect(eligible).not_to include("CI") # Catcher can't go to CI
    end

    it "includes natural positions plus eligible flex positions for a second baseman" do
      player = create(:player, positions: "2B")
      eligible = subject.eligible_positions_for(player)

      expect(eligible).to include("2B")     # Natural position
      expect(eligible).to include("UTIL")   # Batter can go to UTIL
      expect(eligible).to include("MI")     # 2B can go to MI
      expect(eligible).to include("BENCH")  # Anyone can go to bench
      expect(eligible).not_to include("CI") # 2B can't go to CI
    end

    it "includes natural positions plus eligible flex positions for a first baseman" do
      player = create(:player, positions: "1B")
      eligible = subject.eligible_positions_for(player)

      expect(eligible).to include("1B")     # Natural position
      expect(eligible).to include("UTIL")   # Batter can go to UTIL
      expect(eligible).to include("CI")     # 1B can go to CI
      expect(eligible).to include("BENCH")  # Anyone can go to bench
      expect(eligible).not_to include("MI") # 1B can't go to MI
    end

    it "includes pitcher position and bench only" do
      player = create(:player, positions: "SP")
      eligible = subject.eligible_positions_for(player)

      expect(eligible).to include("SP")     # Natural position
      expect(eligible).to include("BENCH")  # Anyone can go to bench
      expect(eligible).not_to include("UTIL") # Pitcher can't go to UTIL
      expect(eligible).not_to include("MI")   # Pitcher can't go to MI
      expect(eligible).not_to include("CI")   # Pitcher can't go to CI
    end

    it "includes all eligible positions for multi-position middle infielder" do
      player = create(:player, positions: "2B,SS")
      eligible = subject.eligible_positions_for(player)

      expect(eligible).to include("2B", "SS")  # Natural positions
      expect(eligible).to include("UTIL")      # Batter can go to UTIL
      expect(eligible).to include("MI")        # 2B/SS can go to MI
      expect(eligible).to include("BENCH")     # Anyone can go to bench
      expect(eligible).not_to include("CI")    # 2B/SS can't go to CI
    end
  end
end
