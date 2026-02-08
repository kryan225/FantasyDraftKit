require 'rails_helper'

RSpec.describe "EditPlayerModal", type: :system do
  before do
    driven_by(:rack_test)
  end

  let!(:league) { create(:league) }
  let!(:player) { create(:player, name: "Mike Trout", positions: "OF", mlb_team: "LAA", calculated_value: 45, is_drafted: false) }

  describe "clicking a player name" do
    before do
      visit players_path
    end

    it "opens the modal" do
      # Modal should be hidden initially
      expect(page).to have_css(".modal.hidden", visible: :hidden)
      
      # Player link should be present with correct data attributes
      expect(page).to have_css("a.player-link[data-player-id='#{player.id}']")
    end

    it "populates form with player data" do
      # Test that the data attributes are present on player links
      expect(page).to have_css("a.player-link[data-player-name='Mike Trout']")
      expect(page).to have_css("a.player-link[data-player-positions='OF']")
      expect(page).to have_css("a.player-link[data-player-mlb-team='LAA']")
      expect(page).to have_css("a.player-link[data-player-value='45']")
      expect(page).to have_css("a.player-link[data-player-is-drafted='false']")
    end
  end

  describe "form validation" do
    it "requires player name" do
      visit players_path
      expect(page).to have_css("input[name='player[name]'][required]", visible: :hidden)
    end

    it "requires positions" do
      visit players_path
      expect(page).to have_css("input[name='player[positions]'][required]", visible: :hidden)
    end
  end

  describe "modal structure" do
    before do
      visit players_path
    end

    it "has modal with correct Stimulus targets" do
      expect(page).to have_css("[data-edit-player-modal-target='modal']", visible: :hidden)
      expect(page).to have_css("[data-edit-player-modal-target='form']", visible: :hidden)
      expect(page).to have_css("[data-edit-player-modal-target='playerName']", visible: :hidden)
      expect(page).to have_css("[data-edit-player-modal-target='playerPositions']", visible: :hidden)
      expect(page).to have_css("[data-edit-player-modal-target='playerMlbTeam']", visible: :hidden)
      expect(page).to have_css("[data-edit-player-modal-target='playerValue']", visible: :hidden)
      expect(page).to have_css("[data-edit-player-modal-target='playerIsDrafted']", visible: :hidden)
    end

    it "has close button with correct Stimulus action" do
      expect(page).to have_css("button[data-action='click->edit-player-modal#close']", visible: :hidden)
    end

    it "has player links with correct Stimulus actions" do
      expect(page).to have_css("a[data-action='click->edit-player-modal#open']")
    end
  end

  describe "multiple player links" do
    let!(:second_player) { create(:player, name: "Aaron Judge", positions: "OF", mlb_team: "NYY", calculated_value: 42, is_drafted: true) }

    before do
      visit players_path
    end

    it "renders links for both players" do
      expect(page).to have_css("a.player-link[data-player-id='#{player.id}']")
      expect(page).to have_css("a.player-link[data-player-id='#{second_player.id}']")
    end

    it "has unique data attributes for each player" do
      expect(page).to have_css("a.player-link[data-player-name='Mike Trout']")
      expect(page).to have_css("a.player-link[data-player-name='Aaron Judge']")
    end
  end
end
