class CheckInsController < ApplicationController
  before_action :authenticate_user!

  def update
    check_in = current_user.check_ins.find(params[:id])
    changed = check_in.respond!(answer: params[:answer].to_s)
    respond_to do |format|
      format.html { redirect_to root_path, status: :see_other, notice: changed ? "Got it. Your answer is saved." : "This check-in has already been handled." }
      format.json { render json: { id: check_in.id, status: check_in.reload.status, changed: changed } }
    end
  rescue ArgumentError => error
    respond_to do |format|
      format.html { redirect_to root_path, status: :see_other, alert: error.message }
      format.json { render json: { error: error.message }, status: :unprocessable_entity }
    end
  end
end
