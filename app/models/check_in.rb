class CheckIn < ApplicationRecord
  belongs_to :commitment

  enum :status, { pending: "pending", snoozed: "snoozed", done: "done", skipped: "skipped", canceled: "canceled" }, validate: true
  validates :due_at, presence: true

  # Lock order matches dispatch: commitment first, occurrence second.
  # Repeated responses to a completed occurrence are harmless.
  def respond!(answer:, now: Time.current)
    raise ArgumentError, "Choose done, later, or skip" unless %w[done later skip].include?(answer)

    commitment.with_lock do
      with_lock do
        return false unless pending?
        return false unless commitment.active?

        if answer == "later"
          update!(status: "snoozed", due_at: now + 5.minutes)
          commitment.update!(next_due_at: due_at)
        else
          update!(status: answer == "done" ? "done" : "skipped", responded_at: now)
          commitment.update!(next_due_at: now + commitment.interval_minutes.minutes)
        end
      end
    end
    true
  end
end
