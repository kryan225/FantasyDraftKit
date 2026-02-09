# frozen_string_literal: true

require "rails_helper"

RSpec.describe DraftBoardController, type: :controller do
  describe "GET #show" do
    context "when one league exists" do
      let!(:league) { create(:league, name: "Test League") }
      let!(:team1) { create(:team, league: league, name: "Team 1") }
      let!(:team2) { create(:team, league: league, name: "Team 2") }
      let!(:player1) { create(:player, name: "Player 1", positions: "1B", calculated_value: 25.0) }
      let!(:player2) { create(:player, name: "Player 2", positions: "OF", calculated_value: 20.0, is_drafted: true, team: team1) }
      let!(:draft_pick) { create(:draft_pick, league: league, team: team1, player: player2, price: 20, pick_number: 1, drafted_position: "OF") }

      it "renders successfully without league_id (auto-resolves)" do
        get :show
        expect(response).to have_http_status(:success)
        expect(assigns(:league)).to eq(league)
      end

      it "loads teams ordered by name" do
        get :show
        expect(assigns(:teams)).to eq([team1, team2])
      end

      it "loads draft picks ordered by pick_number" do
        get :show
        expect(assigns(:draft_picks)).to eq([draft_pick])
      end

      it "loads available players ordered by calculated_value descending" do
        get :show
        expect(assigns(:players)).to include(player1)
        expect(assigns(:players)).not_to include(player2)
      end
    end

    context "when explicit league_id is provided" do
      let!(:league1) { create(:league, name: "League 1") }
      let!(:league2) { create(:league, name: "League 2", team_count: 10) }
      let!(:team) { create(:team, league: league2, name: "Team A") }

      it "uses the specified league" do
        get :show, params: { league_id: league2.id }
        expect(response).to have_http_status(:success)
        expect(assigns(:league)).to eq(league2)
      end

      it "raises RecordNotFound for invalid league_id" do
        expect {
          get :show, params: { league_id: 99999 }
        }.to raise_error(ActiveRecord::RecordNotFound)
      end
    end

    context "when multiple leagues exist without league_id" do
      let!(:league1) { create(:league, name: "League 1") }
      let!(:league2) { create(:league, name: "League 2", team_count: 10) }

      it "redirects to leagues index with alert" do
        get :show
        expect(response).to redirect_to(leagues_path)
        expect(flash[:alert]).to eq("Please select a league first.")
      end
    end

    context "when no leagues exist" do
      it "redirects to leagues index with alert" do
        get :show
        expect(response).to redirect_to(leagues_path)
        expect(flash[:alert]).to eq("No leagues found. Please create a league first.")
      end
    end
  end
end
