require 'rails_helper'

RSpec.describe "EditPlayerModal", type: :system, js: true do
  let!(:league) { create(:league) }
  let!(:player) { create(:player, name: "Mike Trout", positions: "OF", mlb_team: "LAA", calculated_value: 45, is_drafted: false) }

  describe "clicking a player name" do
    before do
      visit players_path
    end

    it "opens the modal and displays player info", :aggregate_failures do
      # Modal should be hidden initially
      expect(page).to have_css(".modal.hidden", visible: :hidden)
      
      # Click player name
      click_link "Mike Trout"
      
      # Modal should become visible with player data
      expect(page).to have_css(".modal", visible: :visible)
      expect(page).to have_content("Edit Player")
      
      # Check form fields are populated
      within(".modal") do
        expect(find_field("Player Name").value).to eq("Mike Trout")
        expect(find_field("Position(s)").value).to eq("OF")
        expect(find_field("MLB Team").value).to eq("LAA")
        expect(find_field("Calculated Value ($)").value).to eq("45")
      end
    end

    it "closes modal on Escape key" do
      click_link "Mike Trout"
      expect(page).to have_css(".modal", visible: :visible)
      
      # Press Escape
      page.driver.browser.keyboard.type(:Escape)
      
      # Modal should close
      expect(page).to have_css(".modal.hidden", visible: :hidden)
    end

    it "closes modal on close button click" do
      click_link "Mike Trout"
      expect(page).to have_css(".modal", visible: :visible)
      
      # Click close button
      within(".modal") do
        find(".modal-close").click
      end
      
      # Modal should close
      expect(page).to have_css(".modal.hidden", visible: :hidden)
    end
  end

  describe "form validation" do
    it "validates required fields with confirmation modal" do
      visit players_path
      click_link "Mike Trout"

      within("[data-controller='edit-player-modal']") do
        # Clear required field
        fill_in "Player Name", with: ""
        click_button "Save Changes"
      end

      # Validation error shown in confirmation modal
      within("[data-controller='confirmation-modal']") do
        expect(page).to have_content("Validation Error")
        expect(page).to have_content("Player name is required")
      end
    end
  end

  describe "multiple player links" do
    let!(:second_player) { create(:player, name: "Aaron Judge", positions: "OF", mlb_team: "NYY", calculated_value: 42, is_drafted: true) }

    it "opens modal with correct data for different players", :aggregate_failures do
      visit players_path
      
      # Click first player
      click_link "Mike Trout"
      expect(page).to have_css(".modal", visible: :visible)
      
      within(".modal") do
        expect(find_field("Player Name").value).to eq("Mike Trout")
        expect(find_field("MLB Team").value).to eq("LAA")
        expect(find_field("Mark as Drafted")).not_to be_checked
      end
      
      # Close modal
      find(".modal-close").click
      expect(page).to have_css(".modal.hidden", visible: :hidden)
      
      # Click second player
      click_link "Aaron Judge"
      expect(page).to have_css(".modal", visible: :visible)
      
      within(".modal") do
        expect(find_field("Player Name").value).to eq("Aaron Judge")
        expect(find_field("MLB Team").value).to eq("NYY")
        expect(find_field("Mark as Drafted")).to be_checked
      end
    end
  end

  describe "accessibility and structure" do
    it "has proper semantic HTML structure" do
      visit players_path
      click_link "Mike Trout"
      
      within(".modal") do
        # Check for semantic structure
        expect(page).to have_css(".modal-header")
        expect(page).to have_css(".modal-body")
        expect(page).to have_css(".modal-footer")
        
        # Check for form labels
        expect(page).to have_css("label[for='player-name']")
        expect(page).to have_css("label[for='player-positions']")
      end
    end
  end
end
