require 'rails_helper'

RSpec.describe "UndoPick", type: :system, js: true do
  let!(:league) {
    create(:league,
      auction_budget: 260,
      roster_config: {
        "C" => 1, "1B" => 1, "2B" => 1, "3B" => 1, "SS" => 1,
        "OF" => 3, "CI" => 1, "MI" => 1, "UTIL" => 2,
        "SP" => 5, "RP" => 2
      }
    )
  }
  let!(:team) { create(:team, league: league, name: "Test Team", budget_remaining: 100) }
  let!(:player) { create(:player, name: "Mike Trout", positions: "OF", mlb_team: "LAA", calculated_value: 45) }
  let!(:draft_pick) { create(:draft_pick, league: league, team: team, player: player, price: 45, drafted_position: "OF") }

  before do
    visit draft_board_path
  end

  describe "undo confirmation modal" do
    it "shows confirmation modal when clicking Undo button", :aggregate_failures do
      # Find and click the Undo button
      within("#draft-picks") do
        click_button "Undo"
      end

      # Confirmation modal should appear with danger styling
      within("[data-controller='confirmation-modal']") do
        expect(page).to have_content("Undo Draft Pick?")
        expect(page).to have_content("Are you sure you want to undo this pick?")
        expect(page).to have_content("This will refund $45 to Test Team")
        expect(page).to have_button("Undo Pick")
        expect(page).to have_button("Keep Pick")
      end
    end

    it "does not undo pick when clicking Cancel", :aggregate_failures do
      within("#draft-picks") do
        click_button "Undo"
      end

      # Click cancel
      within("[data-controller='confirmation-modal']") do
        click_button "Keep Pick"
      end

      # Modal closes
      expect(page).to have_css("[data-controller='confirmation-modal'] .modal.hidden", visible: :hidden)

      # Pick still exists
      within("#draft-picks") do
        expect(page).to have_content("Mike Trout")
      end
    end

    it "allows undo when clicking confirm", :aggregate_failures do
      within("#draft-picks") do
        click_button "Undo"
      end

      # Confirmation modal is visible
      expect(page).to have_css("[data-controller='confirmation-modal'] .modal", visible: :visible)

      # Click confirm
      within("[data-controller='confirmation-modal']") do
        click_button "Undo Pick"
      end

      # Modal closes after confirmation
      expect(page).to have_css("[data-controller='confirmation-modal'] .modal.hidden", visible: :hidden)

      # Form submission is triggered (actual deletion tested in controller specs)
    end
  end
end
