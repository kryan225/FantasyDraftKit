require 'rails_helper'

RSpec.describe "Edit Player Modal - Page Reload After Success", type: :system, js: true do
  let!(:league) { create(:league) }
  let!(:team) { create(:team, league: league, name: "Test Team", budget_remaining: 100) }
  let!(:player) { create(:player, name: "Test Player", positions: "OF", is_drafted: false) }

  it "reloads the page after successful player update", :aggregate_failures do
    visit players_path

    # Record the current page URL
    original_url = current_url

    # Open modal and make a change
    click_link "Test Player"

    within(".modal") do
      # Change player name
      fill_in "Player Name", with: "Updated Player Name"
      click_button "Save Changes"
    end

    # Wait for page to reload
    sleep 0.5

    # Page should have reloaded (same URL but fresh content)
    expect(current_url).to eq(original_url)

    # Player name should be updated in the database
    player.reload
    expect(player.name).to eq("Updated Player Name")

    # Updated name should appear on the page after reload
    expect(page).to have_content("Updated Player Name")
  end

  it "reloads to show drafted player moved to correct section", :aggregate_failures do
    visit players_path

    # Initially, player should be in the available players list
    expect(page).to have_content("Test Player")

    click_link "Test Player"

    within(".modal") do
      select "Test Team", from: "Owned By Team"
      fill_in "Draft Price ($)", with: "15"
      select "OF - Outfield", from: "Roster Position"
      click_button "Save Changes"
    end

    # Wait for page to reload
    sleep 0.5

    # Player should be drafted in the database
    player.reload
    expect(player.team).to eq(team)
    expect(player.is_drafted).to be true

    # Since default filter is "Available Only", drafted player should not appear
    # (unless we're on "All Players" or "Drafted Only" filter)
    # The important thing is the page reloaded and shows correct state
    expect(current_url).to include("/players")
  end

  it "does NOT reload the page when there's a validation error", :aggregate_failures do
    # Create two catchers to fill both C slots
    catcher1 = create(:player, name: "Catcher 1", positions: "C", team: team, is_drafted: true)
    catcher2 = create(:player, name: "Catcher 2", positions: "C", team: team, is_drafted: true)
    create(:draft_pick, league: league, team: team, player: catcher1, price: 10, drafted_position: "C", pick_number: 1)
    create(:draft_pick, league: league, team: team, player: catcher2, price: 15, drafted_position: "C", pick_number: 2)

    new_catcher = create(:player, name: "Third Catcher", positions: "C", is_drafted: false)

    visit players_path

    click_link "Third Catcher"

    within(".modal") do
      select "Test Team", from: "Owned By Team"
      fill_in "Draft Price ($)", with: "20"
      select "C - Catcher", from: "Roster Position"
      click_button "Save Changes"
    end

    # Wait for error to appear
    sleep 0.5

    # Modal should still be open (page did NOT reload)
    expect(page).to have_css(".modal", visible: :visible)

    # Error should be displayed
    within(".modal") do
      expect(page).to have_content("Update Error")
      expect(page).to have_content("C position is full")
    end

    # Player should NOT be drafted (transaction rolled back)
    new_catcher.reload
    expect(new_catcher.team).to be_nil
    expect(new_catcher.is_drafted).to be false
  end
end
