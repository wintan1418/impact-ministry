# Public volunteer intake. Mounted at:
#
#   GET  /volunteer  → #new    (editorial hero + audience cards + intake form)
#   POST /volunteer  → #create
#
# Mirrors PartnershipsController. Submissions arrive via Turbo Stream;
# success/failure replace the `volunteer-form` frame in place. No toasts
# (CLAUDE.md §3). Editors are notified by VolunteerNotificationJob.
class VolunteersController < ApplicationController
  include TurnstileProtectable

  def new
    @volunteer = Volunteer.new
  end

  def create
    @volunteer = Volunteer.new(volunteer_params)

    unless verify_turnstile!
      flash.delete(:alert)
      @error_message = "We couldn't verify you're human. Please try again."
      render_submission_failure
      return
    end

    if @volunteer.save
      VolunteerNotificationJob.perform_later(@volunteer.id)
      render_submission_success
    else
      @error_message = @volunteer.errors.full_messages.first.presence ||
                       "Please look over the form and try again."
      render_submission_failure
    end
  end

  private

  def volunteer_params
    params.require(:volunteer).permit(
      :name,
      :email,
      :phone,
      :availability,
      :gifts,
      :message,
      interest_areas: []
    )
  end

  def render_submission_success
    respond_to do |format|
      format.turbo_stream { render :create, status: :ok }
      format.html         { redirect_to volunteer_path, notice: "Thank you. A real person on our team will write back within a few days." }
    end
  end

  def render_submission_failure
    respond_to do |format|
      format.turbo_stream { render :create, status: :unprocessable_entity }
      format.html         { render :new, status: :unprocessable_entity }
    end
  end
end
