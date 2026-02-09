require 'rails_helper'

RSpec.describe "Edit Player Modal - Google Search Link", type: :system, js: true do
  let!(:league) { create(:league) }
  let!(:player) { create(:player, name: "Mike Trout", positions: "OF", mlb_team: "LAA", is_drafted: false) }

  it "displays a Google search link with the player's name", :aggregate_failures do
    visit players_path

    click_link "Mike Trout"

    within(".modal") do
      # Google search link should be present
      search_link = find('a', text: /Search/)

      # Link should have correct href with encoded player name
      expect(search_link[:href]).to eq("https://www.google.com/search?q=Mike%20Trout")

      # Link should open in new tab
      expect(search_link[:target]).to eq("_blank")
      expect(search_link[:rel]).to include("noopener")
    end
  end

  it "updates the search link when different players are opened", :aggregate_failures do
    second_player = create(:player, name: "Aaron Judge", positions: "OF", mlb_team: "NYY", is_drafted: false)

    visit players_path

    # Open first player
    click_link "Mike Trout"

    within(".modal") do
      search_link = find('a', text: /Search/)
      expect(search_link[:href]).to eq("https://www.google.com/search?q=Mike%20Trout")
    end

    # Close modal
    find(".modal-close").click
    expect(page).to have_css(".modal.hidden", visible: :hidden)

    # Open second player
    click_link "Aaron Judge"

    within(".modal") do
      search_link = find('a', text: /Search/)
      expect(search_link[:href]).to eq("https://www.google.com/search?q=Aaron%20Judge")
    end
  end

  it "handles player names with special characters", :aggregate_failures do
    special_player = create(:player, name: "José Ramírez", positions: "3B", mlb_team: "CLE", is_drafted: false)

    visit players_path

    click_link "José Ramírez"

    within(".modal") do
      search_link = find('a', text: /Search/)

      # Special characters should be properly URL encoded
      expect(search_link[:href]).to eq("https://www.google.com/search?q=Jos%C3%A9%20Ram%C3%ADrez")
    end
  end
end
