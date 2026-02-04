require 'rails_helper'

RSpec.describe "Api::V1::DraftPicks", type: :request do
  describe "GET /index" do
    it "returns http success" do
      get "/api/v1/draft_picks/index"
      expect(response).to have_http_status(:success)
    end
  end

  describe "GET /create" do
    it "returns http success" do
      get "/api/v1/draft_picks/create"
      expect(response).to have_http_status(:success)
    end
  end

  describe "GET /update" do
    it "returns http success" do
      get "/api/v1/draft_picks/update"
      expect(response).to have_http_status(:success)
    end
  end

  describe "GET /destroy" do
    it "returns http success" do
      get "/api/v1/draft_picks/destroy"
      expect(response).to have_http_status(:success)
    end
  end

end
