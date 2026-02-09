require 'rails_helper'

RSpec.describe "Players Team Assignment via Draft/Drop", type: :request do
  let!(:league) { create(:league) }
  let!(:team1) { create(:team, league: league, name: "Team Alpha", budget_remaining: 100) }
  let!(:team2) { create(:team, league: league, name: "Team Beta", budget_remaining: 100) }
  let!(:player) { create(:player, name: "Test Player", positions: "1B", team: nil, is_drafted: false) }

  describe "PATCH /players/:id with team assignment" do
    context "when assigning unowned player to a team" do
      it "creates a draft pick and assigns team", :aggregate_failures do
        expect {
          patch player_path(player), params: {
            player: {
              team_id: team1.id,
              price: 10,
              drafted_position: "1B"
            }
          }
        }.to change { DraftPick.count }.by(1)

        player.reload
        expect(player.team_id).to eq(team1.id)
        expect(player.is_drafted).to be true

        draft_pick = DraftPick.last
        expect(draft_pick.player).to eq(player)
        expect(draft_pick.team).to eq(team1)
        expect(draft_pick.price).to eq(10)
        expect(draft_pick.drafted_position).to eq("1B")
      end

      it "deducts budget from team", :aggregate_failures do
        expect {
          patch player_path(player), params: {
            player: {
              team_id: team1.id,
              price: 15,
              drafted_position: "1B"
            }
          }
        }.to change { team1.reload.budget_remaining }.from(100).to(85)
      end
    end

    context "when changing player from one team to another" do
      let!(:existing_pick) do
        create(:draft_pick,
          league: league,
          team: team1,
          player: player,
          price: 10,
          drafted_position: "1B",
          pick_number: 1
        )
      end

      before do
        player.update!(team: team1, is_drafted: true)
        team1.update!(budget_remaining: 90) # 100 - 10
      end

      it "drops from old team and drafts to new team", :aggregate_failures do
        expect {
          patch player_path(player), params: {
            player: {
              team_id: team2.id,
              price: 12,
              drafted_position: "UTIL"
            }
          }
        }.to change { DraftPick.count }.by(0) # One destroyed, one created

        player.reload
        expect(player.team).to eq(team2)
        expect(player.is_drafted).to be true

        # Old pick should be gone
        expect(DraftPick.exists?(existing_pick.id)).to be false

        # New pick should exist
        new_pick = DraftPick.find_by(player: player)
        expect(new_pick.team).to eq(team2)
        expect(new_pick.price).to eq(12)
        expect(new_pick.drafted_position).to eq("UTIL")
      end

      it "refunds old team and deducts from new team", :aggregate_failures do
        patch player_path(player), params: {
          player: {
            team_id: team2.id,
            price: 12,
            drafted_position: "UTIL"
          }
        }

        expect(team1.reload.budget_remaining).to eq(100) # Refunded 10
        expect(team2.reload.budget_remaining).to eq(88)  # 100 - 12
      end
    end

    context "when dropping player (setting team to nil)" do
      let!(:existing_pick) do
        create(:draft_pick,
          league: league,
          team: team1,
          player: player,
          price: 10,
          drafted_position: "1B",
          pick_number: 1
        )
      end

      before do
        player.update!(team: team1, is_drafted: true)
        team1.update!(budget_remaining: 90) # 100 - 10
      end

      it "removes draft pick and marks player available", :aggregate_failures do
        expect {
          patch player_path(player), params: {
            player: { team_id: "" }
          }
        }.to change { DraftPick.count }.by(-1)

        player.reload
        expect(player.team_id).to be_nil
        expect(player.is_drafted).to be false
        expect(DraftPick.exists?(existing_pick.id)).to be false
      end

      it "refunds team budget" do
        expect {
          patch player_path(player), params: {
            player: { team_id: "" }
          }
        }.to change { team1.reload.budget_remaining }.from(90).to(100)
      end
    end

    context "when roster validation fails" do
      before do
        # Fill up all 1B slots for team1
        roster_config = league.roster_config
        roster_config["1B"].times do |i|
          create(:draft_pick,
            league: league,
            team: team1,
            player: create(:player, name: "Player #{i}", positions: "1B"),
            price: 1,
            drafted_position: "1B",
            pick_number: i + 1
          )
        end
      end

      it "does not create draft pick and returns error", :aggregate_failures do
        expect {
          patch player_path(player), params: {
            player: {
              team_id: team1.id,
              price: 10,
              drafted_position: "1B"
            }
          }, headers: { "Accept" => "text/vnd.turbo-stream.html" }
        }.not_to change { DraftPick.count }

        player.reload
        expect(player.team_id).to be_nil
        expect(player.is_drafted).to be false
      end

      it "does not deduct budget on validation failure" do
        expect {
          patch player_path(player), params: {
            player: {
              team_id: team1.id,
              price: 10,
              drafted_position: "1B"
            }
          }, headers: { "Accept" => "text/vnd.turbo-stream.html" }
        }.not_to change { team1.reload.budget_remaining }
      end
    end
  end
end
