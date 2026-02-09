require 'rails_helper'

RSpec.describe "Edit Player Modal from Roster Page", type: :system, js: true do
  let!(:league) { create(:league) }
  let!(:team) { create(:team, league: league, name: "My Team", budget_remaining: 100) }
  let!(:player) { create(:player, name: "Roster Player", positions: "1B/OF", team: team, is_drafted: true) }
  let!(:draft_pick) do
    create(:draft_pick,
      league: league,
      team: team,
      player: player,
      price: 30,
      drafted_position: "1B",
      pick_number: 1
    )
  end

  it "pre-populates team, price, and position fields with draft data", :aggregate_failures do
    visit team_path(team)

    # Click player name from roster
    click_link "Roster Player"

    within(".modal") do
      # Team should be pre-selected
      expect(page).to have_select("Owned By Team", selected: "My Team")

      # Price field should be visible and populated with actual draft price
      expect(page).to have_field("Draft Price ($)", with: "30", visible: :visible)

      # Position field should be visible and populated with actual drafted position
      expect(page).to have_select("Roster Position", selected: "1B - First Base", visible: :visible)

      # Player info should be correct
      expect(page).to have_field("Player Name", with: "Roster Player")
      expect(page).to have_field("Position(s)", with: "1B/OF")
    end
  end

  it "shows price and position fields since player is already owned", :aggregate_failures do
    visit team_path(team)

    click_link "Roster Player"

    within(".modal") do
      # These fields should be visible because a team is selected
      expect(page).to have_css("[data-edit-player-modal-target='priceField']", visible: :visible)
      expect(page).to have_css("[data-edit-player-modal-target='positionField']", visible: :visible)
    end
  end
end
