require 'rails_helper'

RSpec.describe "DraftBoard", type: :request do
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

  # Create a variety of players for comprehensive testing
  let!(:available_catcher) { create(:player, name: "John Doe", positions: "C", mlb_team: "NYY", calculated_value: 25, is_drafted: false, interested: false) }
  let!(:available_first_baseman) { create(:player, name: "Jane Smith", positions: "1B", mlb_team: "BOS", calculated_value: 30, is_drafted: false, interested: true) }
  let!(:available_outfielder) { create(:player, name: "Bob Johnson", positions: "OF", mlb_team: "LAD", calculated_value: 20, is_drafted: false, interested: false) }
  let!(:available_pitcher) { create(:player, name: "Mike Wilson", positions: "SP", mlb_team: "NYM", calculated_value: 15, is_drafted: false, interested: true) }
  let!(:drafted_catcher) { create(:player, name: "Tom Brown", positions: "C", mlb_team: "CHC", calculated_value: 22, is_drafted: true, interested: false) }
  let!(:drafted_outfielder) { create(:player, name: "Sarah Davis", positions: "OF", mlb_team: "SF", calculated_value: 28, is_drafted: true, interested: false) }

  before do
    # Create draft picks for drafted players
    create(:draft_pick, team: team1, player: drafted_catcher, league: league, drafted_position: "C", price: 22)
    create(:draft_pick, team: team2, player: drafted_outfielder, league: league, drafted_position: "OF", price: 28)
  end

  describe "GET /draft_board" do
    context "without any filters (first visit)" do
      it "returns http success" do
        get draft_board_path(league_id: league.id)
        expect(response).to have_http_status(:success)
      end

      it "defaults to showing available players only" do
        get draft_board_path(league_id: league.id)
        expect(assigns(:players)).to include(available_catcher, available_first_baseman, available_outfielder, available_pitcher)
        expect(assigns(:players)).not_to include(drafted_catcher, drafted_outfielder)
      end

      it "includes all necessary instance variables" do
        get draft_board_path(league_id: league.id)
        expect(assigns(:league)).to eq(league)
        expect(assigns(:teams)).to match_array([team1, team2])
        expect(assigns(:draft_picks)).to be_present
        expect(assigns(:interested_available_players)).to be_present
        expect(assigns(:players)).to be_present
      end
    end

    context "filtering by drafted status" do
      it "shows all players when drafted param is empty string" do
        get draft_board_path(league_id: league.id, drafted: "")
        expect(assigns(:players)).to include(available_catcher, available_first_baseman, available_outfielder, available_pitcher, drafted_catcher, drafted_outfielder)
      end

      it "shows only available players when drafted=false" do
        get draft_board_path(league_id: league.id, drafted: "false")
        expect(assigns(:players)).to include(available_catcher, available_first_baseman, available_outfielder, available_pitcher)
        expect(assigns(:players)).not_to include(drafted_catcher, drafted_outfielder)
      end

      it "shows only drafted players when drafted=true" do
        get draft_board_path(league_id: league.id, drafted: "true")
        expect(assigns(:players)).to include(drafted_catcher, drafted_outfielder)
        expect(assigns(:players)).not_to include(available_catcher, available_first_baseman, available_outfielder, available_pitcher)
      end
    end

    context "filtering by position" do
      it "shows only catchers when position=C" do
        get draft_board_path(league_id: league.id, position: "C")
        expect(assigns(:players)).to include(available_catcher)
        expect(assigns(:players)).not_to include(available_first_baseman, available_outfielder, available_pitcher)
      end

      it "shows only first basemen when position=1B" do
        get draft_board_path(league_id: league.id, position: "1B")
        expect(assigns(:players)).to include(available_first_baseman)
        expect(assigns(:players)).not_to include(available_catcher, available_outfielder, available_pitcher)
      end

      it "shows only outfielders when position=OF" do
        get draft_board_path(league_id: league.id, position: "OF")
        expect(assigns(:players)).to include(available_outfielder)
        expect(assigns(:players)).not_to include(available_catcher, available_first_baseman, available_pitcher)
      end

      it "shows only pitchers when position=SP" do
        get draft_board_path(league_id: league.id, position: "SP")
        expect(assigns(:players)).to include(available_pitcher)
        expect(assigns(:players)).not_to include(available_catcher, available_first_baseman, available_outfielder)
      end
    end

    context "filtering by search term" do
      it "finds players by partial name match (case insensitive)" do
        get draft_board_path(league_id: league.id, search: "john")
        expect(assigns(:players)).to include(available_catcher) # John Doe
        expect(assigns(:players)).to include(available_outfielder) # Bob Johnson
        expect(assigns(:players)).not_to include(available_first_baseman, available_pitcher)
      end

      it "finds players by exact name match" do
        get draft_board_path(league_id: league.id, search: "Jane Smith")
        expect(assigns(:players)).to include(available_first_baseman)
        expect(assigns(:players)).not_to include(available_catcher, available_outfielder, available_pitcher)
      end

      it "returns no results for non-matching search" do
        get draft_board_path(league_id: league.id, search: "NonExistentPlayer")
        expect(assigns(:players)).to be_empty
      end
    end

    context "filtering by interested status" do
      it "shows only interested players when interested=true" do
        get draft_board_path(league_id: league.id, interested: "true")
        expect(assigns(:players)).to include(available_first_baseman, available_pitcher)
        expect(assigns(:players)).not_to include(available_catcher, available_outfielder)
      end

      it "shows all available players when interested is not set" do
        get draft_board_path(league_id: league.id)
        expect(assigns(:players)).to include(available_catcher, available_first_baseman, available_outfielder, available_pitcher)
      end
    end

    context "combined filters" do
      it "filters by position AND drafted status" do
        get draft_board_path(league_id: league.id, position: "C", drafted: "")
        expect(assigns(:players)).to include(available_catcher, drafted_catcher)
        expect(assigns(:players)).not_to include(available_first_baseman, available_outfielder, available_pitcher, drafted_outfielder)
      end

      it "filters by search AND position" do
        # Create another catcher with different name
        other_catcher = create(:player, name: "Alex Rodriguez", positions: "C", calculated_value: 18, is_drafted: false)

        get draft_board_path(league_id: league.id, search: "john", position: "C")
        expect(assigns(:players)).to include(available_catcher) # John Doe, C
        expect(assigns(:players)).not_to include(other_catcher, available_first_baseman)
      end

      it "filters by position AND interested status" do
        get draft_board_path(league_id: league.id, position: "1B", interested: "true")
        expect(assigns(:players)).to include(available_first_baseman)
        expect(assigns(:players)).not_to include(available_catcher, available_outfielder, available_pitcher)
      end

      it "filters by search AND drafted status AND position" do
        get draft_board_path(league_id: league.id, search: "john", drafted: "false", position: "C")
        expect(assigns(:players)).to include(available_catcher) # John Doe
        expect(assigns(:players)).not_to include(drafted_catcher) # Not available
      end
    end

    context "sorting" do
      it "sorts by calculated_value descending by default" do
        get draft_board_path(league_id: league.id)
        players = assigns(:players)
        expect(players.first).to eq(available_first_baseman) # $30
        expect(players.last).to eq(available_pitcher) # $15
      end

      it "sorts by name ascending when specified" do
        get draft_board_path(league_id: league.id, sort: "name", direction: "asc")
        players = assigns(:players)
        expect(players.first.name).to eq("Bob Johnson")
        expect(players.last.name).to eq("Mike Wilson")
      end

      it "sorts by name descending when specified" do
        get draft_board_path(league_id: league.id, sort: "name", direction: "desc")
        players = assigns(:players)
        expect(players.first.name).to eq("Mike Wilson")
        expect(players.last.name).to eq("Bob Johnson")
      end

      it "sorts by positions" do
        get draft_board_path(league_id: league.id, sort: "positions", direction: "asc")
        players = assigns(:players)
        expect(players.first).to eq(available_first_baseman) # 1B
        expect(players.last).to eq(available_pitcher) # SP
      end

      it "sorts by mlb_team" do
        get draft_board_path(league_id: league.id, sort: "mlb_team", direction: "asc")
        players = assigns(:players)
        expect(players.first.mlb_team).to eq("BOS")
      end

      it "sorts by calculated_value ascending" do
        get draft_board_path(league_id: league.id, sort: "calculated_value", direction: "asc")
        players = assigns(:players)
        expect(players.first).to eq(available_pitcher) # $15
        expect(players.last).to eq(available_first_baseman) # $30
      end

      it "maintains filters while sorting" do
        get draft_board_path(league_id: league.id, position: "C", sort: "name", direction: "asc")
        players = assigns(:players)
        expect(players).to include(available_catcher)
        expect(players).not_to include(available_first_baseman, available_outfielder, available_pitcher)
      end
    end

    context "sorting by JSONB projection fields" do
      let!(:hitter1) do
        create(:player,
          name: "Hitter One",
          positions: "OF",
          calculated_value: 20,
          is_drafted: false,
          projections: {
            "home_runs" => 30,
            "runs" => 100,
            "rbi" => 95,
            "stolen_bases" => 10,
            "batting_average" => 0.285
          }
        )
      end

      let!(:hitter2) do
        create(:player,
          name: "Hitter Two",
          positions: "OF",
          calculated_value: 18,
          is_drafted: false,
          projections: {
            "home_runs" => 25,
            "runs" => 90,
            "rbi" => 100,
            "stolen_bases" => 20,
            "batting_average" => 0.295
          }
        )
      end

      it "sorts by home_runs descending" do
        get draft_board_path(league_id: league.id, position: "OF", sort: "home_runs", direction: "desc")
        players = assigns(:players)
        expect(players.first).to eq(hitter1) # 30 HR
      end

      it "sorts by stolen_bases ascending" do
        get draft_board_path(league_id: league.id, position: "OF", sort: "stolen_bases", direction: "asc")
        players = assigns(:players)
        expect(players.first).to eq(hitter1) # 10 SB
      end

      it "sorts by batting_average descending" do
        get draft_board_path(league_id: league.id, position: "OF", sort: "batting_average", direction: "desc")
        players = assigns(:players)
        expect(players.first).to eq(hitter2) # .295
      end
    end

    context "edge cases" do
      it "handles empty player database" do
        # Delete draft picks first to avoid foreign key constraint
        DraftPick.destroy_all
        Player.destroy_all
        get draft_board_path(league_id: league.id)
        expect(assigns(:players)).to be_empty
        expect(response).to have_http_status(:success)
      end

      it "handles league with no teams" do
        league.teams.destroy_all
        get draft_board_path(league_id: league.id)
        expect(assigns(:teams)).to be_empty
        expect(response).to have_http_status(:success)
      end

      it "handles invalid sort column (defaults to calculated_value)" do
        get draft_board_path(league_id: league.id, sort: "invalid_column")
        expect(assigns(:players)).to be_present
        expect(response).to have_http_status(:success)
      end

      it "handles players with null calculated_value (sorted to end)" do
        null_value_player = create(:player, name: "Unknown Value", positions: "OF", calculated_value: nil, is_drafted: false)
        get draft_board_path(league_id: league.id, sort: "calculated_value", direction: "desc")
        players = assigns(:players)
        expect(players.last).to eq(null_value_player)
      end
    end

    context "interested players list" do
      it "includes only interested available players" do
        get draft_board_path(league_id: league.id)
        interested_players = assigns(:interested_available_players)
        expect(interested_players).to include(available_first_baseman, available_pitcher)
        expect(interested_players).not_to include(available_catcher, available_outfielder)
      end

      it "sorts interested players by calculated_value descending" do
        get draft_board_path(league_id: league.id)
        interested_players = assigns(:interested_available_players)
        expect(interested_players.first).to eq(available_first_baseman) # $30
        expect(interested_players.last).to eq(available_pitcher) # $15
      end
    end

    context "draft picks list" do
      it "includes all draft picks ordered by pick number descending" do
        get draft_board_path(league_id: league.id)
        draft_picks = assigns(:draft_picks)
        expect(draft_picks.count).to eq(2)
      end

      it "includes team and player associations" do
        get draft_board_path(league_id: league.id)
        draft_picks = assigns(:draft_picks)
        expect(draft_picks.first.team).to be_present
        expect(draft_picks.first.player).to be_present
      end
    end
  end

  describe "filter parameter persistence" do
    it "remembers drafted filter when passed explicitly" do
      get draft_board_path(league_id: league.id, drafted: "")
      expect(controller.params[:drafted]).to eq("")
    end

    it "remembers position filter" do
      get draft_board_path(league_id: league.id, position: "C")
      expect(controller.params[:position]).to eq("C")
    end

    it "remembers search filter" do
      get draft_board_path(league_id: league.id, search: "test")
      expect(controller.params[:search]).to eq("test")
    end

    it "remembers interested filter" do
      get draft_board_path(league_id: league.id, interested: "true")
      expect(controller.params[:interested]).to eq("true")
    end

    it "remembers sort parameters" do
      get draft_board_path(league_id: league.id, sort: "name", direction: "asc")
      expect(controller.params[:sort]).to eq("name")
      expect(controller.params[:direction]).to eq("asc")
    end
  end
end
