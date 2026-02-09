require 'rails_helper'

RSpec.describe "League Navigation Tabs", type: :system, js: true do
  let!(:league) { create(:league, name: "Test League") }
  let!(:team1) { create(:team, league: league, name: "Team Alpha") }
  let!(:team2) { create(:team, league: league, name: "Team Beta") }
  let!(:player) { create(:player, name: "Test Player", positions: "OF", is_drafted: false) }

  describe "navigation tabs appearance" do
    it "shows navigation tabs on League Home page", :aggregate_failures do
      visit league_path(league)

      within(".league-nav-tabs") do
        expect(page).to have_link("League Home")
        expect(page).to have_link("Draft Board")
        expect(page).to have_link("Teams")
        expect(page).to have_link("Players")
        expect(page).to have_link("Standings")

        # League Home should be active
        league_home_link = find_link("League Home")
        expect(league_home_link[:class]).to include("active")
      end
    end

    it "shows navigation tabs on Draft Board page", :aggregate_failures do
      visit draft_board_path

      within(".league-nav-tabs") do
        expect(page).to have_link("League Home")
        expect(page).to have_link("Draft Board")
        expect(page).to have_link("Teams")
        expect(page).to have_link("Players")
        expect(page).to have_link("Standings")

        # Draft Board should be active
        draft_board_link = find_link("Draft Board")
        expect(draft_board_link[:class]).to include("active")
      end
    end

    it "shows navigation tabs on Teams page", :aggregate_failures do
      visit league_teams_path(league)

      within(".league-nav-tabs") do
        expect(page).to have_link("League Home")
        expect(page).to have_link("Draft Board")
        expect(page).to have_link("Teams")
        expect(page).to have_link("Players")
        expect(page).to have_link("Standings")

        # Teams should be active
        teams_link = find_link("Teams")
        expect(teams_link[:class]).to include("active")
      end
    end

    it "shows navigation tabs on Players page", :aggregate_failures do
      visit league_players_path(league)

      within(".league-nav-tabs") do
        expect(page).to have_link("League Home")
        expect(page).to have_link("Draft Board")
        expect(page).to have_link("Teams")
        expect(page).to have_link("Players")
        expect(page).to have_link("Standings")

        # Players should be active
        players_link = find_link("Players")
        expect(players_link[:class]).to include("active")
      end
    end

    it "shows navigation tabs on Standings page", :aggregate_failures do
      visit standings_path

      within(".league-nav-tabs") do
        expect(page).to have_link("League Home")
        expect(page).to have_link("Draft Board")
        expect(page).to have_link("Teams")
        expect(page).to have_link("Players")
        expect(page).to have_link("Standings")

        # Standings should be active
        standings_link = find_link("Standings")
        expect(standings_link[:class]).to include("active")
      end
    end
  end

  describe "navigation functionality" do
    it "navigates between pages using the tabs", :aggregate_failures do
      visit draft_board_path

      # Navigate to League Home
      within(".league-nav-tabs") do
        click_link "League Home"
      end
      expect(page).to have_current_path(league_path(league))
      expect(find_link("League Home")[:class]).to include("active")

      # Navigate to Teams
      within(".league-nav-tabs") do
        click_link "Teams"
      end
      expect(page).to have_current_path(league_teams_path(league))
      expect(find_link("Teams")[:class]).to include("active")

      # Navigate to Players
      within(".league-nav-tabs") do
        click_link "Players"
      end
      expect(page).to have_current_path(league_players_path(league))
      expect(find_link("Players")[:class]).to include("active")

      # Navigate to Standings
      within(".league-nav-tabs") do
        click_link "Standings"
      end
      expect(page).to have_current_path(standings_path)
      expect(find_link("Standings")[:class]).to include("active")

      # Navigate to Draft Board
      within(".league-nav-tabs") do
        click_link "Draft Board"
      end
      expect(page).to have_current_path(draft_board_path)
      expect(find_link("Draft Board")[:class]).to include("active")
    end
  end

  describe "no navigation tabs on pages without league context" do
    it "does not show tabs on the leagues index page" do
      visit leagues_path

      expect(page).not_to have_css(".league-nav-tabs")
    end
  end
end
