require 'rails_helper'

RSpec.describe "Api::V1::Players", type: :request do
  describe "GET /index" do
    it "returns http success" do
      get "/api/v1/players/index"
      expect(response).to have_http_status(:success)
    end
  end

  describe "GET /import" do
    it "returns http success" do
      get "/api/v1/players/import"
      expect(response).to have_http_status(:success)
    end
  end

  describe "GET /recalculate_values" do
    it "returns http success" do
      get "/api/v1/players/recalculate_values"
      expect(response).to have_http_status(:success)
    end
  end

end
