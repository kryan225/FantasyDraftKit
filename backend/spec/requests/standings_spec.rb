require 'rails_helper'

RSpec.describe "Standings", type: :request do
  describe "GET /standings" do
    context "when one league exists" do
      let!(:league) { create(:league, name: "Test League") }
      let!(:team1) { create(:team, league: league, name: "Team A") }
      let!(:team2) { create(:team, league: league, name: "Team B") }

      let!(:hitter1) do
        create(:player,
          name: "Hitter 1",
          positions: "OF",
          team: team1,
          projections: {
            "home_runs" => 40,
            "runs" => 100,
            "rbi" => 120,
            "stolen_bases" => 30,
            "batting_average" => 0.300,
            "at_bats" => 600
          }
        )
      end

      let!(:pitcher1) do
        create(:player,
          name: "Pitcher 1",
          positions: "SP",
          team: team1,
          projections: {
            "wins" => 15,
            "saves" => 0,
            "strikeouts" => 200,
            "era" => 3.00,
            "whip" => 1.10,
            "innings_pitched" => 200
          }
        )
      end

      let!(:hitter2) do
        create(:player,
          name: "Hitter 2",
          positions: "1B",
          team: team2,
          projections: {
            "home_runs" => 35,
            "runs" => 90,
            "rbi" => 110,
            "stolen_bases" => 5,
            "batting_average" => 0.280,
            "at_bats" => 550
          }
        )
      end

      before do
        # Create draft picks to associate players with teams
        create(:draft_pick, league: league, team: team1, player: hitter1, price: 30, pick_number: 1, drafted_position: "OF")
        create(:draft_pick, league: league, team: team1, player: pitcher1, price: 25, pick_number: 2, drafted_position: "SP")
        create(:draft_pick, league: league, team: team2, player: hitter2, price: 28, pick_number: 3, drafted_position: "1B")
      end

      it "returns http success" do
        get standings_path
        expect(response).to have_http_status(:success)
      end

      it "displays team standings" do
        get standings_path
        expect(response.body).to include("Team A")
        expect(response.body).to include("Team B")
      end

      it "calculates counting stats correctly" do
        get standings_path
        expect(assigns(:team_stats).find { |ts| ts[:team].id == team1.id }[:stats][:home_runs]).to eq(40)
        expect(assigns(:team_stats).find { |ts| ts[:team].id == team1.id }[:stats][:wins]).to eq(15)
      end

      it "calculates rate stats correctly" do
        get standings_path
        team1_stats = assigns(:team_stats).find { |ts| ts[:team].id == team1.id }[:stats]
        expect(team1_stats[:batting_average]).to eq(0.300)
        expect(team1_stats[:era]).to eq(3.00)
      end

      it "calculates rankings correctly" do
        get standings_path
        rankings = assigns(:rankings)

        # Team A should rank higher in HR (40 > 35)
        expect(rankings[team1.id][:home_runs]).to eq(1)
        expect(rankings[team2.id][:home_runs]).to eq(2)

        # Team A should rank higher in SB (30 > 5)
        expect(rankings[team1.id][:stolen_bases]).to eq(1)
        expect(rankings[team2.id][:stolen_bases]).to eq(2)
      end

      it "calculates total rotisserie points" do
        get standings_path
        rankings = assigns(:rankings)

        expect(rankings[team1.id][:total_points]).to be > 0
        expect(rankings[team2.id][:total_points]).to be > 0
      end
    end

    context "when league_id is provided" do
      let!(:league1) { create(:league, name: "League 1") }
      let!(:league2) { create(:league, name: "League 2") }
      let!(:team1) { create(:team, league: league1, name: "Team 1") }
      let!(:team2) { create(:team, league: league2, name: "Team 2") }

      it "shows standings for the specified league" do
        get league_standings_path(league2)
        expect(response).to have_http_status(:success)
        expect(assigns(:league)).to eq(league2)
      end
    end

    context "when multiple leagues exist without league_id" do
      let!(:league1) { create(:league, name: "League 1") }
      let!(:league2) { create(:league, name: "League 2") }

      it "redirects to leagues index with alert" do
        get standings_path
        expect(response).to redirect_to(leagues_path)
        expect(flash[:alert]).to eq("Please select a league first.")
      end
    end

    context "when no leagues exist" do
      it "redirects to leagues index with alert" do
        get standings_path
        expect(response).to redirect_to(leagues_path)
        expect(flash[:alert]).to eq("No leagues found. Please create a league first.")
      end
    end
  end
end
