require 'rails_helper'

RSpec.describe DashboardController, type: :controller do

  describe "GET #plan_comparison" do
    it "returns http success" do
      get :plan_comparison
      expect(response).to have_http_status(:success)
    end
  end

end
