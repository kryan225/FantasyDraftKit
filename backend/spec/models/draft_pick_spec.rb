require 'rails_helper'

RSpec.describe DraftPick, type: :model do
  let(:league) { create(:league, auction_budget: 260) }
  let(:team) { create(:team, league: league, budget_remaining: 260) }
  let(:player) { create(:player, name: "Test Player", positions: "C", is_drafted: false) }

  describe "validations" do
    it "requires a team" do
      pick = build(:draft_pick, team: nil, league: league, player: player)
      expect(pick).not_to be_valid
    end

    it "requires a player" do
      pick = build(:draft_pick, team: team, league: league, player: nil)
      expect(pick).not_to be_valid
    end

    it "requires a price" do
      pick = build(:draft_pick, team: team, league: league, player: player, price: nil)
      expect(pick).not_to be_valid
    end
  end

  describe "callbacks" do
    describe "after_create" do
      it "marks player as drafted" do
        expect(player.is_drafted).to be false

        create(:draft_pick, team: team, league: league, player: player, price: 25)

        expect(player.reload.is_drafted).to be true
      end

      it "deducts price from team budget" do
        expect(team.budget_remaining).to eq(260)

        create(:draft_pick, team: team, league: league, player: player, price: 25)

        expect(team.reload.budget_remaining).to eq(235)
      end
    end

    describe "after_destroy" do
      it "marks player as available again" do
        pick = create(:draft_pick, team: team, league: league, player: player, price: 25)
        expect(player.reload.is_drafted).to be true

        pick.destroy

        expect(player.reload.is_drafted).to be false
      end

      it "refunds price to team budget" do
        pick = create(:draft_pick, team: team, league: league, player: player, price: 25)
        expect(team.reload.budget_remaining).to eq(235)

        pick.destroy

        expect(team.reload.budget_remaining).to eq(260)
      end
    end
  end

  describe "associations" do
    it "belongs to a league" do
      pick = create(:draft_pick, team: team, league: league, player: player, price: 10)
      expect(pick.league).to eq(league)
    end

    it "belongs to a team" do
      pick = create(:draft_pick, team: team, league: league, player: player, price: 10)
      expect(pick.team).to eq(team)
    end

    it "belongs to a player" do
      pick = create(:draft_pick, team: team, league: league, player: player, price: 10)
      expect(pick.player).to eq(player)
    end
  end

  describe "drafted_position" do
    it "stores the roster position where player was placed" do
      pick = create(:draft_pick, team: team, league: league, player: player, price: 10, drafted_position: "C")
      expect(pick.drafted_position).to eq("C")
    end

    it "allows flex positions" do
      pick = create(:draft_pick, team: team, league: league, player: player, price: 10, drafted_position: "UTIL")
      expect(pick.drafted_position).to eq("UTIL")
    end
  end

  describe "position eligibility validation" do
    context "when player is eligible for the position" do
      it "allows drafting a catcher to C position" do
        catcher = create(:player, positions: "C", is_drafted: false)
        pick = build(:draft_pick, team: team, league: league, player: catcher, price: 10, drafted_position: "C")
        expect(pick).to be_valid
      end

      it "allows drafting a multi-position player to any of their positions" do
        multi_pos = create(:player, positions: "1B,OF", is_drafted: false)
        pick1 = build(:draft_pick, team: team, league: league, player: multi_pos, price: 10, drafted_position: "1B")
        pick2 = build(:draft_pick, team: team, league: league, player: multi_pos, price: 10, drafted_position: "OF")
        expect(pick1).to be_valid
        expect(pick2).to be_valid
      end

      it "allows drafting a batter to UTIL position" do
        outfielder = create(:player, positions: "OF", is_drafted: false)
        pick = build(:draft_pick, team: team, league: league, player: outfielder, price: 10, drafted_position: "UTIL")
        expect(pick).to be_valid
      end

      it "allows drafting a 2B to MI position" do
        second_baseman = create(:player, positions: "2B", is_drafted: false)
        pick = build(:draft_pick, team: team, league: league, player: second_baseman, price: 10, drafted_position: "MI")
        expect(pick).to be_valid
      end

      it "allows drafting a 1B to CI position" do
        first_baseman = create(:player, positions: "1B", is_drafted: false)
        pick = build(:draft_pick, team: team, league: league, player: first_baseman, price: 10, drafted_position: "CI")
        expect(pick).to be_valid
      end

      # Note: BENCH test skipped - default league has 0 bench slots
      # Position eligibility allows it, but roster slot availability prevents it
    end

    context "when player is NOT eligible for the position" do
      it "prevents drafting a catcher to 1B position" do
        catcher = create(:player, positions: "C", is_drafted: false)
        pick = build(:draft_pick, team: team, league: league, player: catcher, price: 10, drafted_position: "1B")
        expect(pick).not_to be_valid
        expect(pick.errors[:drafted_position]).to include(match(/not eligible for 1B/))
      end

      it "prevents drafting an outfielder to C position" do
        outfielder = create(:player, positions: "OF", is_drafted: false)
        pick = build(:draft_pick, team: team, league: league, player: outfielder, price: 10, drafted_position: "C")
        expect(pick).not_to be_valid
        expect(pick.errors[:drafted_position]).to include(match(/not eligible for C/))
      end

      it "prevents drafting an outfielder to MI position" do
        outfielder = create(:player, positions: "OF", is_drafted: false)
        pick = build(:draft_pick, team: team, league: league, player: outfielder, price: 10, drafted_position: "MI")
        expect(pick).not_to be_valid
        expect(pick.errors[:drafted_position]).to include(match(/not eligible for MI/))
      end

      it "prevents drafting a pitcher to UTIL position" do
        pitcher = create(:player, positions: "SP", is_drafted: false)
        pick = build(:draft_pick, team: team, league: league, player: pitcher, price: 10, drafted_position: "UTIL")
        expect(pick).not_to be_valid
        expect(pick.errors[:drafted_position]).to include(match(/not eligible for UTIL/))
      end

      it "provides helpful error message with eligible positions" do
        catcher = create(:player, name: "Mike Trout", positions: "C", is_drafted: false)
        pick = build(:draft_pick, team: team, league: league, player: catcher, price: 10, drafted_position: "SS")
        pick.valid?
        error_message = pick.errors[:drafted_position].first
        expect(error_message).to include("Mike Trout")
        expect(error_message).to include("not eligible for SS")
        expect(error_message).to include("Eligible positions:")
        expect(error_message).to include("C")
      end
    end
  end
end
