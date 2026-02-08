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
end
