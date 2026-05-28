# Public contact form. Mounted at POST /contact.
#
# The GET /contact view is owned by `pages#show` (the editor-managed
# `contact` Page record). This controller only handles submissions —
# success replaces the form turbo-frame with a quiet confirmation, failure
# re-renders the frame with inline errors (no toast — CLAUDE.md §3).
#
# A FeedbackNotificationJob is enqueued on success so editors get an
# email alert without blocking the request.
class FeedbackMessagesController < ApplicationController
  include TurnstileProtectable

  def create
    @feedback_message = FeedbackMessage.new(feedback_message_params)

    unless verify_turnstile!
      flash.delete(:alert) # inline-only; no toast
      @feedback_message.errors.add(:base, "We couldn't verify you're human. Please try again.")
      render_submission_failure
      return
    end

    if @feedback_message.save
      FeedbackNotificationJob.perform_later(@feedback_message.id)
      render_submission_success
    else
      render_submission_failure
    end
  end

  private

  def feedback_message_params
    if params[:feedback_message].present?
      params.require(:feedback_message).permit(:name, :email, :subject, :body, :kind)
    else
      # Tolerate top-level params for parity with other public form patterns.
      params.permit(:name, :email, :subject, :body, :kind)
    end
  end

  def render_submission_success
    respond_to do |format|
      format.turbo_stream { render :create, status: :ok }
      format.html         { redirect_to contact_page_path, notice: "We received your note. Thank you." }
    end
  end

  def render_submission_failure
    respond_to do |format|
      format.turbo_stream { render :create, status: :unprocessable_entity }
      format.html         { redirect_to contact_page_path, alert: @feedback_message.errors.full_messages.to_sentence.presence || "We couldn't save that." }
    end
  end
end
