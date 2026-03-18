require 'rails_helper'

RSpec.describe "Dashboard", type: :request do
  describe "GET /" do
    context "when authenticated" do
      let(:user) { User.create!(email: "test@example.com", password: "password123") }

      before { sign_in user }

      it "returns http success" do
        get root_path
        expect(response).to have_http_status(:success)
      end
    end

    context "when not authenticated" do
      it "redirects to sign in" do
        get root_path
        expect(response).to redirect_to(new_user_session_path)
      end
    end
  end
end
