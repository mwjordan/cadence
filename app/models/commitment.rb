class Commitment < ApplicationRecord
  belongs_to :user
  has_many :check_ins, dependent: :destroy

  validates :title, presence: true, length: { maximum: 120 }
  validates :interval_minutes, numericality: { only_integer: true, greater_than_or_equal_to: 1, less_than_or_equal_to: 1440 }
  validates :next_due_at, presence: true

  scope :due, ->(now = Time.current) { where(active: true).where(next_due_at: ..now) }

  def dispatch!(now: Time.current)
    with_lock do
      return unless active? && next_due_at <= now

      check_in = check_ins.where(status: %w[pending snoozed]).first
      if check_in
        check_in.update!(status: "pending") if check_in.snoozed?
      else
        check_ins.create!(status: "pending", due_at: next_due_at)
      end
      # A pending occurrence waits for an answer instead of generating duplicates.
      # The next interval begins after done/skip; later moves this occurrence.
      update!(next_due_at: now + interval_minutes.minutes) unless check_in&.pending?
    end
  end

  def pause!
    with_lock do
      update!(active: false)
      check_ins.where(status: %w[pending snoozed]).update_all(status: "canceled", updated_at: Time.current)
    end
  end
end
