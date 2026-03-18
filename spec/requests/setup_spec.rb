require 'rails_helper'

RSpec.describe "Setup", type: :request do
  describe "GET /setup" do
    it "returns http success" do
      get setup_path
      expect(response).to have_http_status(:success)
    end

    it "displays the current app name" do
      get setup_path
      expect(response.body).to include("RailsAppStarterKit")
    end
  end

  describe "PATCH /setup" do
    context "with a valid name" do
      after do
        # Restore original files after test
        AppRenameService.new("Rails App Starter Kit").call
      end

      it "renames the app and redirects" do
        patch setup_path, params: { app_name: "My Test App" }
        expect(response).to redirect_to(setup_path)
        follow_redirect!
        expect(response.body).to include("renamed")
      end
    end

    context "with a blank name" do
      it "shows an error" do
        patch setup_path, params: { app_name: "" }
        expect(response).to have_http_status(:unprocessable_entity)
      end
    end

    context "with an invalid name" do
      it "shows an error for names starting with numbers" do
        patch setup_path, params: { app_name: "123app" }
        expect(response).to have_http_status(:unprocessable_entity)
      end
    end
  end
end
