require 'rails_helper'

RSpec.describe "Edit Player Modal - Position Eligibility Validation", type: :system, js: true do
  let!(:league) { create(:league) }
  let!(:team) { create(:team, league: league, name: "Test Team", budget_remaining: 100) }

  describe "prevents drafting to ineligible positions" do
    it "shows error when trying to draft a pitcher to UTIL position", :aggregate_failures do
      pitcher = create(:player, name: "Pitcher", positions: "SP", is_drafted: false)

      visit players_path

      click_link "Pitcher"

      within(".modal") do
        select "Test Team", from: "Owned By Team"
        fill_in "Draft Price ($)", with: "10"
        select "UTIL - Utility", from: "Roster Position"
        click_button "Save Changes"
      end

      # Wait for turbo stream to update
      sleep 0.5

      # Modal should stay open with error
      expect(page).to have_css(".modal", visible: :visible)
      expect(page).not_to have_css(".modal.hidden")

      within(".modal") do
        expect(page).to have_content("Update Error")
        expect(page).to have_content("not eligible for UTIL")
      end
    end

    it "shows error when trying to draft a catcher to 1B position", :aggregate_failures do
      catcher = create(:player, name: "Catcher Only", positions: "C", is_drafted: false)

      visit players_path

      click_link "Catcher Only"

      within(".modal") do
        select "Test Team", from: "Owned By Team"
        fill_in "Draft Price ($)", with: "10"
        select "1B - First Base", from: "Roster Position"
        click_button "Save Changes"
      end

      # Wait for turbo stream to update
      sleep 0.5

      # Modal should stay open with error
      expect(page).to have_css(".modal", visible: :visible)

      within(".modal") do
        expect(page).to have_content("Update Error")
        expect(page).to have_content("not eligible for 1B")
      end
    end

    it "shows error when trying to draft an outfielder to MI position", :aggregate_failures do
      outfielder = create(:player, name: "Pure Outfielder", positions: "OF", is_drafted: false)

      visit players_path

      click_link "Pure Outfielder"

      within(".modal") do
        select "Test Team", from: "Owned By Team"
        fill_in "Draft Price ($)", with: "10"
        select "MI - Middle Infield", from: "Roster Position"
        click_button "Save Changes"
      end

      # Wait for turbo stream to update
      sleep 0.5

      # Modal should stay open with error
      expect(page).to have_css(".modal", visible: :visible)

      within(".modal") do
        expect(page).to have_content("Update Error")
        expect(page).to have_content("not eligible for MI")
      end
    end

    it "provides helpful error message with eligible positions", :aggregate_failures do
      catcher = create(:player, name: "Mike Zunino", positions: "C", is_drafted: false)

      visit players_path

      click_link "Mike Zunino"

      within(".modal") do
        select "Test Team", from: "Owned By Team"
        fill_in "Draft Price ($)", with: "10"
        select "SS - Shortstop", from: "Roster Position"
        click_button "Save Changes"

        sleep 0.5

        # Error should include eligible positions
        expect(page).to have_content("Mike Zunino")
        expect(page).to have_content("not eligible for SS")
        expect(page).to have_content("Eligible positions:")
        expect(page).to have_content("C") # Should list catcher as eligible
      end
    end
  end

  describe "allows drafting to eligible positions" do
    it "allows drafting a multi-position player to any eligible position", :aggregate_failures do
      multi_pos = create(:player, name: "Multi Position", positions: "2B,SS", is_drafted: false)

      visit players_path

      click_link "Multi Position"

      within(".modal") do
        select "Test Team", from: "Owned By Team"
        fill_in "Draft Price ($)", with: "10"
        select "MI - Middle Infield", from: "Roster Position"
        click_button "Save Changes"
      end

      # Modal should close on success
      expect(page).to have_css(".modal.hidden", visible: :hidden)

      # Player should be drafted
      multi_pos.reload
      expect(multi_pos.team).to eq(team)
      expect(multi_pos.is_drafted).to be true
    end

    it "allows drafting a batter to UTIL position", :aggregate_failures do
      first_baseman = create(:player, name: "First Baseman", positions: "1B", is_drafted: false)

      visit players_path

      click_link "First Baseman"

      within(".modal") do
        select "Test Team", from: "Owned By Team"
        fill_in "Draft Price ($)", with: "10"
        select "UTIL - Utility", from: "Roster Position"
        click_button "Save Changes"
      end

      # Modal should close on success
      expect(page).to have_css(".modal.hidden", visible: :hidden)

      # Player should be drafted
      first_baseman.reload
      expect(first_baseman.team).to eq(team)
    end

    it "allows drafting a 1B to CI position", :aggregate_failures do
      first_baseman = create(:player, name: "Corner Infielder", positions: "1B", is_drafted: false)

      visit players_path

      click_link "Corner Infielder"

      within(".modal") do
        select "Test Team", from: "Owned By Team"
        fill_in "Draft Price ($)", with: "10"
        select "CI - Corner Infield", from: "Roster Position"
        click_button "Save Changes"
      end

      # Modal should close on success
      expect(page).to have_css(".modal.hidden", visible: :hidden)

      # Player should be drafted to CI
      first_baseman.reload
      draft_pick = first_baseman.draft_picks.first
      expect(draft_pick.drafted_position).to eq("CI")
    end
  end

  describe "allows fixing position eligibility error" do
    it "allows user to fix ineligible position and successfully draft", :aggregate_failures do
      pitcher = create(:player, name: "Starting Pitcher", positions: "SP", is_drafted: false)

      visit players_path

      click_link "Starting Pitcher"

      within(".modal") do
        select "Test Team", from: "Owned By Team"
        fill_in "Draft Price ($)", with: "10"

        # First attempt - ineligible position
        select "UTIL - Utility", from: "Roster Position"
        click_button "Save Changes"

        sleep 0.5

        # Error shown
        expect(page).to have_content("not eligible for UTIL")

        # Fix by selecting SP position
        select "SP - Starting Pitcher", from: "Roster Position"
        click_button "Save Changes"
      end

      # Modal should close on success
      expect(page).to have_css(".modal.hidden", visible: :hidden)

      # Player should be drafted
      pitcher.reload
      expect(pitcher.team).to eq(team)
      expect(pitcher.is_drafted).to be true
    end
  end
end
