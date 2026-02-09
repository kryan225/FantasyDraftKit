require 'rails_helper'

RSpec.describe "Edit Player Modal - Price Field", type: :system, js: true do
  let!(:league) { create(:league) }
  let!(:team1) { create(:team, league: league, name: "Team Alpha", budget_remaining: 100) }
  let!(:undrafted_player) { create(:player, name: "Undrafted Player", positions: "OF", mlb_team: "LAA", calculated_value: 30, is_drafted: false) }
  let!(:drafted_player) { create(:player, name: "Drafted Player", positions: "1B", mlb_team: "NYY", team: team1, calculated_value: 40, is_drafted: true) }
  let!(:draft_pick) do
    create(:draft_pick,
      league: league,
      team: team1,
      player: drafted_player,
      price: 25,
      drafted_position: "1B",
      pick_number: 1
    )
  end

  describe "price field visibility and state" do
    it "always shows the Draft Price field for undrafted players with N/A value", :aggregate_failures do
      visit players_path

      click_link "Undrafted Player"

      within(".modal") do
        price_field = find_field("Draft Price ($)")

        # Price field should be visible
        expect(price_field).to be_visible

        # Price field should display "N/A"
        expect(price_field.value).to eq("N/A")

        # Price field should be readonly (JavaScript sets readOnly property)
        expect(page.evaluate_script("document.getElementById('player-price').readOnly")).to be true
      end
    end

    it "always shows the Draft Price field for drafted players with actual price", :aggregate_failures do
      visit players_path

      click_link "Drafted Player"

      within(".modal") do
        price_field = find_field("Draft Price ($)")

        # Price field should be visible
        expect(price_field).to be_visible

        # Price field should display actual draft price
        expect(price_field.value).to eq("25")

        # Price field should NOT be readonly (editable)
        expect(page.evaluate_script("document.getElementById('player-price').readOnly")).to be false
      end
    end

    it "changes from N/A to editable when team is selected", :aggregate_failures do
      visit players_path

      click_link "Undrafted Player"

      within(".modal") do
        price_field = find_field("Draft Price ($)")

        # Initially N/A and readonly
        expect(price_field.value).to eq("N/A")
        expect(page.evaluate_script("document.getElementById('player-price').readOnly")).to be true

        # Select a team
        select "Team Alpha", from: "Owned By Team"

        # Price should change to "1" and become editable
        expect(price_field.value).to eq("1")
        expect(page.evaluate_script("document.getElementById('player-price').readOnly")).to be false
      end
    end

    it "changes back to N/A when team is deselected", :aggregate_failures do
      visit players_path

      click_link "Undrafted Player"

      within(".modal") do
        price_field = find_field("Draft Price ($)")

        # Select a team
        select "Team Alpha", from: "Owned By Team"
        expect(price_field.value).to eq("1")

        # Deselect team
        select "-- Unowned --", from: "Owned By Team"

        # Price should change back to N/A and become readonly
        expect(price_field.value).to eq("N/A")
        expect(page.evaluate_script("document.getElementById('player-price').readOnly")).to be true
      end
    end
  end
end
