class SetupController < ApplicationController
  def show
    @current_name = current_app_name
  end

  def update
    new_name = params[:app_name]

    if new_name.blank?
      flash.now[:alert] = "App name cannot be blank."
      @current_name = current_app_name
      render :show, status: :unprocessable_entity
      return
    end

    result = AppRenameService.new(new_name).call

    flash[:notice] = "App renamed to \"#{result[:human_name]}\" successfully! " \
                     "Updated #{result[:files_updated].count} file(s). " \
                     "Restart your server for changes to take effect."
    redirect_to setup_path
  rescue ArgumentError => e
    flash.now[:alert] = e.message
    @current_name = current_app_name
    render :show, status: :unprocessable_entity
  end

  private

  def current_app_name
    Rails.application.class.module_parent_name
  end
end
