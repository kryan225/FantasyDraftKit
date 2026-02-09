require 'rails_helper'

RSpec.describe "Edit Player Modal - UI State Management", type: :system, js: true do
  let!(:league) { create(:league) }
  let!(:team) { create(:team, league: league, name: "Test Team") }
  let!(:player) { create(:player, name: "Test Player", positions: "OF", team: nil, is_drafted: false) }

  it "resets submit button state when modal reopens", :aggregate_failures do
    visit players_path

    # Open modal and save
    click_link "Test Player"
    within(".modal") do
      select "Test Team", from: "Owned By Team"
      fill_in "Draft Price ($)", with: "10"
      select "OF", from: "Roster Position"
      click_button "Save Changes"
    end

    # Wait for modal to close
    expect(page).to have_css(".modal.hidden", visible: :hidden)

    # Reopen modal - button should not be stuck on "Saving..."
    click_link "Test Player"
    within(".modal") do
      expect(page).to have_button("Save Changes", disabled: false)
      expect(page).not_to have_button("Saving...")
    end
  end

  it "displays updated team ownership when modal reopens", :aggregate_failures do
    visit players_path

    # Initial state - unowned
    click_link "Test Player"
    within(".modal") do
      expect(page).to have_select("Owned By Team", selected: "-- Unowned --")
      find(".modal-close").click
    end

    # Wait for modal to close
    expect(page).to have_css(".modal.hidden", visible: :hidden)

    # Change team ownership
    click_link "Test Player"
    within(".modal") do
      select "Test Team", from: "Owned By Team"
      fill_in "Draft Price ($)", with: "10"
      select "OF", from: "Roster Position"
      click_button "Save Changes"
    end

    # Wait for modal to close and Turbo Stream to update
    expect(page).to have_css(".modal.hidden", visible: :hidden)
    sleep 0.5 # Give Turbo Stream time to update DOM

    # Reopen modal - should show new team
    click_link "Test Player"
    within(".modal") do
      expect(page).to have_select("Owned By Team", selected: "Test Team")
      expect(page).to have_field("Draft Price ($)", with: "10")
      expect(page).to have_select("Roster Position", selected: "OF - Outfield")
    end
  end

  it "updates player data in database when team ownership changes", :aggregate_failures do
    visit players_path

    # Initial state - Available
    expect(player.team).to be_nil
    expect(player.is_drafted).to be false

    # Change team ownership
    click_link "Test Player"
    within(".modal") do
      select "Test Team", from: "Owned By Team"
      fill_in "Draft Price ($)", with: "15"
      select "OF", from: "Roster Position"
      click_button "Save Changes"
    end

    # Wait for modal to close
    expect(page).to have_css(".modal.hidden", visible: :hidden)

    # Verify database was updated
    player.reload
    expect(player.team).to eq(team)
    expect(player.is_drafted).to be true

    # Reopen modal to verify UI shows updated team
    click_link "Test Player"
    within(".modal") do
      expect(page).to have_select("Owned By Team", selected: "Test Team")
      expect(page).to have_field("Draft Price ($)", with: "15")
      expect(page).to have_select("Roster Position", selected: "OF - Outfield")
    end
  end
end
