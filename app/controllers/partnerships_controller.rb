# Public partnership intake. Mounted at:
#
#   GET  /partner   → #new    (editorial hero + audience cards + intake form)
#   POST /partner   → #create
#
# Submissions arrive via Turbo Stream; success/failure replace the
# `partnership-form` frame in place. No toasts (CLAUDE.md §3).
# Editors are notified by `PartnershipNotificationJob` so they can answer
# from their own inbox.
class PartnershipsController < ApplicationController
  include TurnstileProtectable

  def new
    @partnership = Partnership.new
  end

  def create
    @partnership = Partnership.new(partnership_params)

    unless verify_turnstile!
      flash.delete(:alert) # inline-only; no toast
      @error_message = "We couldn't verify you're human. Please try again."
      render_submission_failure
      return
    end

    if @partnership.save
      PartnershipNotificationJob.perform_later(@partnership.id)
      render_submission_success
    else
      @error_message = @partnership.errors.full_messages.first.presence ||
                       "Please look over the form and try again."
      render_submission_failure
    end
  end

  private

  def partnership_params
    params.require(:partnership).permit(
      :organization_name,
      :contact_name,
      :contact_email,
      :contact_phone,
      :organization_type,
      :message,
      interest_areas: []
    )
  end

  def render_submission_success
    respond_to do |format|
      format.turbo_stream { render :create, status: :ok }
      format.html         { redirect_to partner_path, notice: "Thank you. A real person on our team will write back within a few days." }
    end
  end

  def render_submission_failure
    respond_to do |format|
      format.turbo_stream { render :create, status: :unprocessable_entity }
      format.html         { render :new, status: :unprocessable_entity }
    end
  end
end
