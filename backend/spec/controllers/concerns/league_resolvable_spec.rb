# frozen_string_literal: true

require "rails_helper"

# Test controller to include the concern
class TestLeagueResolvableController < ApplicationController
  include LeagueResolvable

  def test_action
    league = current_league
    return unless league

    render plain: "League: #{league.id}"
  end
end

RSpec.describe LeagueResolvable, type: :controller do
  controller(TestLeagueResolvableController) do
    def index
      test_action
    end
  end

  before do
    routes.draw { get "index" => "test_league_resolvable#index" }
  end

  describe "#current_league" do
    context "when league_id is provided in params" do
      let!(:league1) { League.create!(name: "League 1", team_count: 12, auction_budget: 260, keeper_limit: 3) }
      let!(:league2) { League.create!(name: "League 2", team_count: 10, auction_budget: 260, keeper_limit: 3) }

      it "returns the specified league" do
        get :index, params: { league_id: league2.id }
        expect(response.body).to eq("League: #{league2.id}")
      end

      it "raises RecordNotFound for invalid league_id" do
        expect {
          get :index, params: { league_id: 99999 }
        }.to raise_error(ActiveRecord::RecordNotFound)
      end
    end

    context "when only one league exists and no league_id is provided" do
      let!(:league) { League.create!(name: "Only League", team_count: 12, auction_budget: 260, keeper_limit: 3) }

      it "automatically uses the only league (KISS principle)" do
        get :index
        expect(response.body).to eq("League: #{league.id}")
      end
    end

    context "when multiple leagues exist and no league_id is provided" do
      let!(:league1) { League.create!(name: "League 1", team_count: 12, auction_budget: 260, keeper_limit: 3) }
      let!(:league2) { League.create!(name: "League 2", team_count: 10, auction_budget: 260, keeper_limit: 3) }

      it "redirects to leagues index with alert" do
        get :index
        expect(response).to redirect_to(leagues_path)
        expect(flash[:alert]).to eq("Please select a league first.")
      end
    end

    context "when no leagues exist" do
      it "redirects to leagues index with alert" do
        get :index
        expect(response).to redirect_to(leagues_path)
        expect(flash[:alert]).to eq("No leagues found. Please create a league first.")
      end
    end
  end

  describe "#ensure_league" do
    context "when current_league resolves successfully" do
      let!(:league) { League.create!(name: "Test League", team_count: 12, auction_budget: 260, keeper_limit: 3) }

      it "does not redirect" do
        get :index
        expect(response).to have_http_status(:success)
      end
    end

    context "when current_league returns nil (multiple leagues without ID)" do
      let!(:league1) { League.create!(name: "League 1", team_count: 12, auction_budget: 260, keeper_limit: 3) }
      let!(:league2) { League.create!(name: "League 2", team_count: 10, auction_budget: 260, keeper_limit: 3) }

      it "redirects" do
        get :index
        expect(response).to redirect_to(leagues_path)
      end
    end
  end
end
