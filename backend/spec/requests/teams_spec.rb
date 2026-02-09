require 'rails_helper'

RSpec.describe "Teams", type: :request do
  let!(:league) { create(:league, name: "Test League") }
  let!(:team1) { create(:team, league: league, name: "Alpha Team", budget_remaining: 150) }
  let!(:team2) { create(:team, league: league, name: "Beta Team", budget_remaining: 200) }

  describe "GET /teams" do
    context "with a single league" do
      it "returns http success" do
        get teams_path
        expect(response).to have_http_status(:success)
      end

      it "assigns all teams from the league" do
        get teams_path
        expect(assigns(:teams)).to match_array([team1, team2])
      end

      it "orders teams by name" do
        get teams_path
        expect(assigns(:teams)).to eq([team1, team2])
      end
    end

    context "with multiple leagues" do
      let!(:league2) { create(:league, name: "Second League") }
      let!(:team3) { create(:team, league: league2, name: "Gamma Team") }

      it "redirects to leagues index with helpful message" do
        get teams_path
        expect(response).to redirect_to(leagues_path)
        follow_redirect!
        expect(response.body).to include("Please select a league")
      end
    end
  end

  describe "GET /leagues/:league_id/teams" do
    it "returns http success" do
      get league_teams_path(league)
      expect(response).to have_http_status(:success)
    end

    it "assigns teams from the specified league only" do
      league2 = create(:league, name: "Second League")
      team3 = create(:team, league: league2, name: "Gamma Team")

      get league_teams_path(league)
      expect(assigns(:teams)).to match_array([team1, team2])
      expect(assigns(:teams)).not_to include(team3)
    end

    it "orders teams by name" do
      get league_teams_path(league)
      expect(assigns(:teams)).to eq([team1, team2])
    end
  end
end
