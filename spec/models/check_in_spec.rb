require "rails_helper"

RSpec.describe CheckIn, type: :model do
  include ActiveSupport::Testing::TimeHelpers

  let(:user) { User.create!(email: "someone@example.com", password: "a-long-test-password") }
  let(:commitment) { user.commitments.create!(title: "Move", interval_minutes: 120, next_due_at: 1.minute.ago) }

  it "dispatches only one open occurrence even when the dispatcher runs again" do
    commitment.dispatch!
    travel 121.minutes do
      commitment.dispatch!
      commitment.dispatch!
    end
    expect(commitment.check_ins.pending.count).to eq(1)
  end

  it "persists completion and ignores a duplicate answer" do
    commitment.dispatch!
    check_in = commitment.check_ins.sole
    expect(check_in.respond!(answer: "done")).to be(true)
    expect(check_in.respond!(answer: "later")).to be(false)
    expect(check_in.reload).to be_done
    expect(check_in.responded_at).to be_present
    expect(commitment.reload.next_due_at).to be_within(2.seconds).of(120.minutes.from_now)
  end

  it "snoozes the same occurrence, then makes it available after five minutes" do
    freeze_time do
      commitment.dispatch!
      check_in = commitment.check_ins.sole
      check_in.respond!(answer: "later")
      expect(check_in.reload).to be_snoozed
      travel 4.minutes
      commitment.dispatch!
      expect(check_in.reload).to be_snoozed
      travel 1.minute
      commitment.dispatch!
      expect(check_in.reload).to be_pending
      expect(commitment.check_ins.count).to eq(1)
    end
  end

  it "stops an open occurrence when paused and refuses a stale reply" do
    commitment.dispatch!
    check_in = commitment.check_ins.sole
    commitment.pause!
    expect(check_in.respond!(answer: "done")).to be(false)
    expect(check_in.reload).to be_canceled
  end

  it "rejects unknown replies without changing state" do
    commitment.dispatch!
    check_in = commitment.check_ins.sole
    expect { check_in.respond!(answer: "perhaps") }.to raise_error(ArgumentError)
    expect(check_in.reload).to be_pending
  end
end
