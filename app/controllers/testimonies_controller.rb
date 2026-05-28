# Public testimony wall + submission. Mounted at:
#
#   GET  /testimonies        → #index   (approved + featured wall)
#   GET  /testify            → #new     (submission form)
#   POST /testimonies        → #create
#
# Approval is editor-only — the public form always writes `approved: false`.
# Submissions arrive via Turbo Stream; success/failure replace the
# `testimony-form` frame in place. No toasts (CLAUDE.md §3).
class TestimoniesController < ApplicationController
  include TurnstileProtectable

  def index
    @testimonies = Testimony.approved.recent_first.limit(40)
    @featured    = Testimony.approved.featured.recent_first.limit(3)
  end

  def new
    @testimony = Testimony.new
  end

  def create
    @testimony = Testimony.new(testimony_params)
    @testimony.approved = false
    @testimony.featured = false

    unless verify_turnstile!
      flash.delete(:alert) # we don't toast — error renders inline in the frame
      @error_message = "We couldn't verify you're human. Please try again."
      render_submission_failure
      return
    end

    if @testimony.save
      render_submission_success
    else
      @error_message = @testimony.errors.full_messages.first.presence || "Please look over the form and try again."
      render_submission_failure
    end
  end

  private

  def testimony_params
    params.require(:testimony).permit(:name, :location, :body, :photo)
  end

  def render_submission_success
    respond_to do |format|
      format.turbo_stream { render :create, status: :ok }
      format.html         { redirect_to testimonies_path, notice: "Thank you. We'll read this carefully." }
    end
  end

  def render_submission_failure
    respond_to do |format|
      format.turbo_stream { render :create, status: :unprocessable_entity }
      format.html         { render :new, status: :unprocessable_entity }
    end
  end
end
