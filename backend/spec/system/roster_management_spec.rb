require 'rails_helper'

RSpec.describe "Roster Management", type: :system, js: true do
  let!(:league) { create(:league) }
  let!(:team) { create(:team, league: league, name: "Test Team", budget_remaining: 200) }

  describe "moving a player to a different position" do
    it "allows user to click-to-move a player between eligible positions", :aggregate_failures do
      # Setup: Create a 2B player
      second_baseman = create(:player, name: "Second Baseman", positions: "2B", is_drafted: true)
      create(:draft_pick, team: team, player: second_baseman, league: league, drafted_position: "2B", price: 20)

      visit team_path(team)

      # Verify player is at 2B initially
      expect(page).to have_content("Second Baseman")

      # Click the 2B position to select the player
      find("td[data-current-position='2B']").click

      # Eligible positions should be highlighted
      expect(page).to have_css("td[data-position='MI'].available-move")
      expect(page).to have_css("td[data-position='UTIL'].available-move")

      # Click MI to move player there
      find("td[data-position='MI'].available-move").click

      # Player should now be at MI (roster updates via Turbo Stream)
      within("tr", text: "MI") do
        expect(page).to have_content("Second Baseman")
      end
    end
  end

  describe "roster display" do
    it "shows filled and empty roster slots correctly" do
      # Create players at various positions
      catcher = create(:player, name: "Catcher", positions: "C", is_drafted: true)
      outfielder = create(:player, name: "Outfielder", positions: "OF", is_drafted: true)

      create(:draft_pick, team: team, player: catcher, league: league, drafted_position: "C", price: 25)
      create(:draft_pick, team: team, player: outfielder, league: league, drafted_position: "OF", price: 30)

      visit team_path(team)

      # Should show filled slots
      expect(page).to have_content("Catcher")
      expect(page).to have_content("Outfielder")

      # Should show empty slots
      expect(page).to have_content("Empty Slot", count: team.league.roster_config.values.sum - 2)
    end
  end
end
