require 'rails_helper'

RSpec.describe Player, type: :model do
  describe "validations" do
    it "requires a name" do
      player = build(:player, name: nil)
      expect(player).not_to be_valid
      expect(player.errors[:name]).to include("can't be blank")
    end

    it "requires positions" do
      player = build(:player, positions: nil)
      expect(player).not_to be_valid
      expect(player.errors[:positions]).to include("can't be blank")
    end
  end

  describe "scopes" do
    let!(:available_player) { create(:player, name: "Available", is_drafted: false) }
    let!(:drafted_player) { create(:player, name: "Drafted", is_drafted: true) }
    let!(:interested_player) { create(:player, name: "Interested", is_drafted: false, interested: true) }

    describe ".available" do
      it "returns only non-drafted players" do
        expect(Player.available).to include(available_player, interested_player)
        expect(Player.available).not_to include(drafted_player)
      end
    end

    describe ".drafted" do
      it "returns only drafted players" do
        expect(Player.drafted).to include(drafted_player)
        expect(Player.drafted).not_to include(available_player, interested_player)
      end
    end

    describe ".interested" do
      it "returns only players marked as interested" do
        expect(Player.interested).to include(interested_player)
        expect(Player.interested).not_to include(available_player, drafted_player)
      end
    end
  end

  describe "position handling" do
    it "stores single position" do
      player = create(:player, positions: "C")
      expect(player.positions).to eq("C")
    end

    it "stores multiple positions as comma-separated string" do
      player = create(:player, positions: "2B,SS,OF")
      expect(player.positions).to eq("2B,SS,OF")
    end
  end

  describe "team ownership and draft status sync" do
    let(:league) { create(:league) }
    let(:team) { create(:team, league: league) }

    context "when team is assigned to player" do
      it "automatically sets is_drafted to true" do
        player = create(:player, team: nil, is_drafted: false)

        player.update(team: team)

        expect(player.is_drafted).to be true
      end
    end

    context "when team is removed from player" do
      it "automatically sets is_drafted to false" do
        player = create(:player, team: team, is_drafted: true)

        player.update(team: nil)

        expect(player.is_drafted).to be false
      end
    end

    context "when team is changed" do
      let(:other_team) { create(:team, league: league, name: "Other Team") }

      it "keeps is_drafted as true" do
        player = create(:player, team: team, is_drafted: true)

        player.update(team: other_team)

        expect(player.is_drafted).to be true
        expect(player.team).to eq(other_team)
      end
    end

    context "when other attributes are updated" do
      it "does not modify is_drafted if team_id unchanged" do
        player = create(:player, team: team, is_drafted: true)
        original_drafted_status = player.is_drafted

        # Update other attributes without changing team
        player.update(name: "New Name")

        # is_drafted should remain unchanged
        expect(player.is_drafted).to eq(original_drafted_status)
        expect(player.team).to eq(team)
      end
    end
  end
end
