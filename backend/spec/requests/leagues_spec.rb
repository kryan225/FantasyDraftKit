require 'rails_helper'

RSpec.describe "Leagues", type: :request do
  describe "GET /index" do
    it "returns http success" do
      get "/leagues/index"
      expect(response).to have_http_status(:success)
    end
  end

  describe "GET /show" do
    it "returns http success" do
      get "/leagues/show"
      expect(response).to have_http_status(:success)
    end
  end

  describe "GET /new" do
    it "returns http success" do
      get "/leagues/new"
      expect(response).to have_http_status(:success)
    end
  end

end
