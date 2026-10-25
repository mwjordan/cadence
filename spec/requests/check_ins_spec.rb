require "rails_helper"

RSpec.describe "Check-ins", type: :request do
  let(:user) { User.create!(email: "owner@example.com", password: "a-long-test-password") }
  let(:other_user) { User.create!(email: "other@example.com", password: "a-long-test-password") }
  let(:commitment) { user.commitments.create!(title: "Move", interval_minutes: 120, next_due_at: 1.minute.ago) }

  before { commitment.dispatch! }

  it "requires authentication" do
    patch check_in_path(commitment.check_ins.sole), params: { answer: "done" }
    expect(response).to redirect_to(new_user_session_path)
  end

  it "prevents another account from answering or reading a check-in" do
    sign_in other_user
    patch check_in_path(commitment.check_ins.sole), params: { answer: "done" }, as: :json
    expect(response).to have_http_status(:not_found)
    sign_in other_user
    get mobile_bootstrap_path, as: :json
    expect(response).to have_http_status(:ok)
    expect(response.parsed_body["check_ins"]).to eq([])
    expect(commitment.check_ins.sole).to be_pending
  end

  it "records the owner's response and exposes only their mobile state" do
    sign_in user
    get mobile_bootstrap_path, as: :json
    expect(response.parsed_body["check_ins"].sole["id"]).to eq(commitment.check_ins.sole.id)
    patch check_in_path(commitment.check_ins.sole), params: { answer: "skip" }, as: :json
    expect(response).to have_http_status(:ok)
    expect(response.parsed_body["status"]).to eq("skipped")
  end

  it "renders the dashboard and accepts a new schedule" do
    sign_in user
    get root_path
    expect(response).to have_http_status(:ok)
    expect(response.body).to include("Your next small step")
    expect {
      post commitments_path, params: { commitment: { title: "Stretch", interval_minutes: 30 } }
    }.to change(user.commitments, :count).by(1)
    expect(response).to redirect_to(root_path)
  end
end
