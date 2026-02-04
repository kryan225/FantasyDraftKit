require 'rails_helper'

RSpec.describe "Api::V1::KeeperHistories", type: :request do
  describe "GET /index" do
    it "returns http success" do
      get "/api/v1/keeper_histories/index"
      expect(response).to have_http_status(:success)
    end
  end

  describe "GET /import_keepers" do
    it "returns http success" do
      get "/api/v1/keeper_histories/import_keepers"
      expect(response).to have_http_status(:success)
    end
  end

  describe "GET /check_keeper_eligibility" do
    it "returns http success" do
      get "/api/v1/keeper_histories/check_keeper_eligibility"
      expect(response).to have_http_status(:success)
    end
  end

end
