require 'rails_helper'

RSpec.describe "ConfirmationModal", type: :system, js: true do
  let!(:league) { create(:league) }
  let!(:player) { create(:player, name: "Mike Trout", positions: "OF", mlb_team: "LAA", calculated_value: 45) }

  describe "validation errors" do
    before do
      visit players_path
      click_link "Mike Trout"
      expect(page).to have_css(".modal", visible: :visible)
    end

    it "shows confirmation modal when player name is empty", :aggregate_failures do
      within("[data-controller='edit-player-modal']") do
        fill_in "Player Name", with: ""
        click_button "Save Changes"
      end

      # Confirmation modal should appear
      within("[data-controller='confirmation-modal']") do
        expect(page).to have_content("Validation Error")
        expect(page).to have_content("Player name is required")
        expect(page).to have_button("OK")
        expect(page).not_to have_button("Cancel")
      end
    end

    it "shows confirmation modal when positions is empty", :aggregate_failures do
      within("[data-controller='edit-player-modal']") do
        fill_in "Position(s)", with: ""
        click_button "Save Changes"
      end

      # Confirmation modal should appear
      within("[data-controller='confirmation-modal']") do
        expect(page).to have_content("Validation Error")
        expect(page).to have_content("At least one position is required")
        expect(page).to have_button("OK")
      end
    end

    it "closes confirmation modal and keeps edit modal open when clicking OK", :aggregate_failures do
      within("[data-controller='edit-player-modal']") do
        fill_in "Player Name", with: ""
        click_button "Save Changes"
      end

      # Confirmation modal appears
      expect(page).to have_css("[data-controller='confirmation-modal'] .modal", visible: :visible)

      # Click OK to dismiss
      within("[data-controller='confirmation-modal']") do
        click_button "OK"
      end

      # Confirmation modal closes
      expect(page).to have_css("[data-controller='confirmation-modal'] .modal.hidden", visible: :hidden)

      # Edit modal remains open so user can fix the error
      expect(page).to have_css("[data-controller='edit-player-modal'] .modal", visible: :visible)
    end
  end

  describe "confirmation modal structure" do
    it "has proper semantic HTML and accessibility", :aggregate_failures do
      visit players_path

      # Check structure exists (modal is hidden by default)
      within("[data-controller='confirmation-modal']") do
        expect(page).to have_css(".modal", visible: :hidden)
        expect(page).to have_css(".modal-header", visible: :hidden)
        expect(page).to have_css(".modal-body", visible: :hidden)
        expect(page).to have_css(".modal-footer", visible: :hidden)
        expect(page).to have_css("[data-confirmation-modal-target='title']", visible: :hidden)
        expect(page).to have_css("[data-confirmation-modal-target='message']", visible: :hidden)
        expect(page).to have_css("[data-confirmation-modal-target='confirmButton']", visible: :hidden)
        expect(page).to have_css("[data-confirmation-modal-target='cancelButton']", visible: :hidden)
      end
    end
  end
end
