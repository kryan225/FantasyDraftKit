require 'rails_helper'

RSpec.describe "Edit Player Modal - Error Handling", type: :system, js: true do
  let!(:league) { create(:league) }
  let!(:team) { create(:team, league: league, name: "Test Team", budget_remaining: 100) }
  let!(:undrafted_player) { create(:player, name: "New Player", positions: "C", mlb_team: "LAA", is_drafted: false) }

  # Create two catchers to fill both C slots
  let!(:catcher1) { create(:player, name: "Catcher 1", positions: "C", team: team, is_drafted: true) }
  let!(:catcher2) { create(:player, name: "Catcher 2", positions: "C", team: team, is_drafted: true) }
  let!(:draft_pick1) do
    create(:draft_pick,
      league: league,
      team: team,
      player: catcher1,
      price: 10,
      drafted_position: "C",
      pick_number: 1
    )
  end
  let!(:draft_pick2) do
    create(:draft_pick,
      league: league,
      team: team,
      player: catcher2,
      price: 15,
      drafted_position: "C",
      pick_number: 2
    )
  end

  it "keeps modal open and shows error when position is full", :aggregate_failures do
    visit players_path

    # Click undrafted player to open modal
    click_link "New Player"

    within(".modal") do
      # Attempt to draft to a full position
      select "Test Team", from: "Owned By Team"
      fill_in "Draft Price ($)", with: "20"
      select "C - Catcher", from: "Roster Position"
      click_button "Save Changes"
    end

    # Wait for turbo stream response
    sleep 0.5

    # Modal should still be visible (not closed)
    expect(page).to have_css(".modal", visible: :visible)
    expect(page).not_to have_css(".modal.hidden")

    # Error message should be displayed within the modal
    within(".modal") do
      expect(page).to have_content("Update Error")
      expect(page).to have_content("C position is full (2/2)")
    end
  end

  it "clears error message when modal is reopened", :aggregate_failures do
    visit players_path

    # First attempt - generate error
    click_link "New Player"

    within(".modal") do
      select "Test Team", from: "Owned By Team"
      fill_in "Draft Price ($)", with: "20"
      select "C - Catcher", from: "Roster Position"
      click_button "Save Changes"

      sleep 0.5

      # Error should be present
      expect(page).to have_content("Update Error")
    end

    # Close modal
    find(".modal-close").click
    expect(page).to have_css(".modal.hidden", visible: :hidden)

    # Reopen modal
    click_link "New Player"

    within(".modal") do
      # Error should be cleared
      expect(page).not_to have_content("Update Error")
      expect(page).not_to have_content("position is full")
    end
  end

  it "allows successful submission after fixing validation error", :aggregate_failures do
    visit players_path

    # Click undrafted player
    click_link "New Player"

    within(".modal") do
      # First attempt - position full
      select "Test Team", from: "Owned By Team"
      fill_in "Draft Price ($)", with: "20"
      select "C - Catcher", from: "Roster Position"
      click_button "Save Changes"

      sleep 0.5

      # Error shown, modal still open
      expect(page).to have_content("C position is full")

      # Fix by selecting UTIL position instead
      select "UTIL - Utility", from: "Roster Position"
      click_button "Save Changes"
    end

    # Modal should close on successful submission
    expect(page).to have_css(".modal.hidden", visible: :hidden)

    # Player should be drafted
    undrafted_player.reload
    expect(undrafted_player.team).to eq(team)
    expect(undrafted_player.is_drafted).to be true
  end
end
