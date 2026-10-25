class DashboardController < ApplicationController
  before_action :authenticate_user!

  def show
    @commitments = current_user.commitments.order(created_at: :desc)
    @pending = current_user.check_ins.pending.includes(:commitment).order(:due_at)
    @history = current_user.check_ins.where(status: %w[done skipped canceled]).includes(:commitment).order(updated_at: :desc).limit(12)
    @commitment = current_user.commitments.new(title: "Take a movement break", interval_minutes: 120)
  end
end
