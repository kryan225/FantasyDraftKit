require 'rails_helper'

RSpec.describe "Edit Player Modal - Draft Data Population", type: :system, js: true do
  let!(:league) { create(:league) }
  let!(:team) { create(:team, league: league, name: "Test Team", budget_remaining: 100) }
  let!(:player) { create(:player, name: "Drafted Player", positions: "OF", team: team, is_drafted: true) }
  let!(:draft_pick) do
    create(:draft_pick,
      league: league,
      team: team,
      player: player,
      price: 25,
      drafted_position: "OF",
      pick_number: 1
    )
  end

  it "populates team, price, and position fields with draft pick data", :aggregate_failures do
    visit players_path

    click_link "Drafted Player"

    within(".modal") do
      # Team should be pre-selected
      expect(page).to have_select("Owned By Team", selected: "Test Team")

      # Price field should be visible and populated
      expect(page).to have_field("Draft Price ($)", with: "25")

      # Position field should be visible and populated
      expect(page).to have_select("Roster Position", selected: "OF - Outfield")
    end
  end

  it "shows price and position fields when team is already selected", :aggregate_failures do
    visit players_path

    click_link "Drafted Player"

    within(".modal") do
      # Price and position fields should be visible since player is owned
      expect(page).to have_css("[data-edit-player-modal-target='priceField']", visible: :visible)
      expect(page).to have_css("[data-edit-player-modal-target='positionField']", visible: :visible)
    end
  end

  context "when player is not drafted" do
    let!(:unowned_player) { create(:player, name: "Free Agent", positions: "1B", team: nil, is_drafted: false) }

    it "defaults to unowned with N/A price", :aggregate_failures do
      visit players_path

      click_link "Free Agent"

      within(".modal") do
        expect(page).to have_select("Owned By Team", selected: "-- Unowned --")

        # Price field should be visible with "N/A" value
        expect(page).to have_css("[data-edit-player-modal-target='priceField']", visible: :visible)
        expect(find_field("Draft Price ($)").value).to eq("N/A")

        # Position field should be hidden
        expect(page).to have_css("[data-edit-player-modal-target='positionField']", visible: :hidden)
      end
    end
  end
end
