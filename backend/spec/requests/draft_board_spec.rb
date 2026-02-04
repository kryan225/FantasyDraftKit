require 'rails_helper'

RSpec.describe "DraftBoards", type: :request do
  describe "GET /show" do
    it "returns http success" do
      get "/draft_board/show"
      expect(response).to have_http_status(:success)
    end
  end

end
