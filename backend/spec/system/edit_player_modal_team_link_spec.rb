require 'rails_helper'

RSpec.describe "Edit Player Modal - Team Link", type: :system, js: true do
  let!(:league) { create(:league) }
  let!(:team) { create(:team, league: league, name: "Test Team", budget_remaining: 100) }
  let!(:undrafted_player) { create(:player, name: "Undrafted Player", positions: "OF", is_drafted: false) }
  let!(:drafted_player) { create(:player, name: "Drafted Player", positions: "1B", team: team, is_drafted: true) }
  let!(:draft_pick) do
    create(:draft_pick,
      league: league,
      team: team,
      player: drafted_player,
      price: 25,
      drafted_position: "1B",
      pick_number: 1
    )
  end

  describe "team link visibility" do
    it "hides team link when no team is selected", :aggregate_failures do
      visit players_path

      click_link "Undrafted Player"

      within(".modal") do
        team_link = find('a', text: /View Team/, visible: :all)

        # Link should be hidden when no team is selected
        expect(team_link).not_to be_visible
      end
    end

    it "shows team link when a team is selected", :aggregate_failures do
      visit players_path

      click_link "Undrafted Player"

      within(".modal") do
        # Initially hidden
        team_link = find('a', text: /View Team/, visible: :all)
        expect(team_link).not_to be_visible

        # Select a team
        select "Test Team", from: "Owned By Team"

        # Link should now be visible
        team_link = find('a', text: /View Team/, visible: :visible)
        expect(team_link).to be_visible
      end
    end

    it "shows team link for already drafted players", :aggregate_failures do
      visit players_path

      click_link "Drafted Player"

      within(".modal") do
        team_link = find('a', text: /View Team/, visible: :visible)

        # Link should be visible since player is drafted
        expect(team_link).to be_visible

        # Link should point to the team page
        expect(team_link[:href]).to include("/teams/#{team.id}")
      end
    end

    it "hides team link when team is deselected", :aggregate_failures do
      visit players_path

      click_link "Undrafted Player"

      within(".modal") do
        # Select a team
        select "Test Team", from: "Owned By Team"

        team_link = find('a', text: /View Team/, visible: :visible)
        expect(team_link).to be_visible

        # Deselect team
        select "-- Unowned --", from: "Owned By Team"

        # Link should be hidden again
        team_link = find('a', text: /View Team/, visible: :all)
        expect(team_link).not_to be_visible
      end
    end
  end

  describe "team link href" do
    it "updates href when different team is selected", :aggregate_failures do
      team2 = create(:team, league: league, name: "Second Team", budget_remaining: 100)

      visit players_path

      click_link "Undrafted Player"

      within(".modal") do
        # Select first team
        select "Test Team", from: "Owned By Team"

        team_link = find('a', text: /View Team/, visible: :visible)
        expect(team_link[:href]).to include("/teams/#{team.id}")

        # Select second team
        select "Second Team", from: "Owned By Team"

        team_link = find('a', text: /View Team/, visible: :visible)
        expect(team_link[:href]).to include("/teams/#{team2.id}")
      end
    end

    it "links to correct team for drafted player", :aggregate_failures do
      visit players_path

      click_link "Drafted Player"

      within(".modal") do
        team_link = find('a', text: /View Team/, visible: :visible)

        # Link should point to the correct team
        expect(team_link[:href]).to include("/teams/#{team.id}")

        # Link should open in new tab
        expect(team_link[:target]).to eq("_blank")
      end
    end
  end
end
