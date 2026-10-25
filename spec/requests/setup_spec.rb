require 'rails_helper'

RSpec.describe "Setup", type: :request do
  describe "GET /setup" do
    it "returns http success" do
      get setup_path
      expect(response).to have_http_status(:success)
    end

    it "displays the current app name" do
      get setup_path
      expect(response.body).to include(Rails.application.class.module_parent_name)
    end
  end

  describe "PATCH /setup" do
    context "with a valid name" do
      before do
        # A request spec must never rewrite the working tree or rename real databases.
        service = instance_double(AppRenameService, call: { human_name: "My Test App", files_updated: [] })
        allow(AppRenameService).to receive(:new).with("My Test App").and_return(service)
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
