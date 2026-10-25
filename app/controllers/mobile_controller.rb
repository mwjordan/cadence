class MobileController < ApplicationController
  before_action :authenticate_user!

  def show
    render json: {
      commitments: current_user.commitments.where(active: true).as_json(only: %i[id title interval_minutes next_due_at]),
      check_ins: current_user.check_ins.pending.includes(:commitment).order(:due_at).map do |check_in|
        { id: check_in.id, title: check_in.commitment.title, due_at: check_in.due_at, response_url: check_in_path(check_in) }
      end
    }
  end
end
