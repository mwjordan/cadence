class CommitmentsController < ApplicationController
  before_action :authenticate_user!

  def create
    @commitment = current_user.commitments.new(commitment_params)
    @commitment.next_due_at = Time.current + @commitment.interval_minutes.to_i.minutes
    if @commitment.save
      redirect_to root_path, status: :see_other, notice: "Check-ins are scheduled."
    else
      redirect_to root_path, status: :see_other, alert: @commitment.errors.full_messages.to_sentence
    end
  end

  def update
    commitment = current_user.commitments.find(params[:id])
    if params[:operation] == "pause"
      commitment.pause!
    elsif params[:operation] == "resume"
      commitment.with_lock { commitment.update!(active: true, next_due_at: Time.current + commitment.interval_minutes.minutes) }
    elsif params[:operation] == "check_now"
      commitment.with_lock do
        commitment.update!(next_due_at: Time.current) if commitment.active?
      end
      commitment.dispatch!
    else
      return head :unprocessable_entity
    end
    redirect_to root_path, status: :see_other, notice: "Schedule updated."
  end

  private

  def commitment_params
    params.require(:commitment).permit(:title, :interval_minutes)
  end
end
