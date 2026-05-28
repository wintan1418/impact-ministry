# Public Prayer Wall.
#
# Mounted at:
#   GET  /pray              → #index       (form + visible wall)
#   POST /pray              → #create      (Turbo Stream)
#   POST /pray/:id/prayed   → #prayed      (Turbo Stream, session-deduped)
#
# Submissions are Turbo Stream by default. On success the form frame is
# replaced with a quiet confirmation; on validation error the same frame is
# re-rendered with inline errors (no toast — CLAUDE.md §3).
#
# `#prayed` only operates on requests in the public `visible` scope. The
# session-scoped `:prayed_for` array dedupes per browser session, so a user
# can't pad the counter by hammering the button.
class PrayerRequestsController < ApplicationController
  include TurnstileProtectable

  def index
    @public_requests = PrayerRequest.visible.limit(60)
    @filter          = wall_filter
    @public_requests = @public_requests.where(status: "answered") if @filter == "answered"
    @prayer_request  = PrayerRequest.new
    @total_prayed    = PrayerRequest.sum(:prayed_count)
  end

  def create
    @prayer_request = PrayerRequest.new(prayer_request_params.merge(status: "new"))

    unless verify_turnstile!
      flash.delete(:alert)
      @prayer_request.errors.add(:base, "We couldn't verify you're human. Please try again.")
      render_form_failure
      return
    end

    if @prayer_request.save
      render_form_success
    else
      render_form_failure
    end
  end

  def prayed
    @prayer_request = PrayerRequest.visible.find_by(id: params[:id])
    return head :not_found unless @prayer_request

    session[:prayed_for] ||= []
    unless session[:prayed_for].include?(@prayer_request.id)
      session[:prayed_for] = session[:prayed_for] + [ @prayer_request.id ]
      @prayer_request.increment_prayed!
    end

    respond_to do |format|
      format.turbo_stream { render :prayed, status: :ok }
      format.html         { redirect_to pray_path, notice: "Thank you for praying." }
    end
  end

  private

  def prayer_request_params
    if params[:prayer_request].present?
      params.require(:prayer_request).permit(:name, :email, :body, :is_anonymous)
    else
      # Tolerate top-level params (matches the email_capture submission pattern).
      params.permit(:name, :email, :body, :is_anonymous)
    end
  end

  def wall_filter
    params[:filter].to_s == "answered" ? "answered" : "all"
  end

  def render_form_success
    respond_to do |format|
      format.turbo_stream { render :create, status: :ok }
      format.html         { redirect_to pray_path, notice: "We've received your prayer." }
    end
  end

  def render_form_failure
    respond_to do |format|
      format.turbo_stream { render :create, status: :unprocessable_entity }
      format.html         { redirect_to pray_path, alert: @prayer_request.errors.full_messages.to_sentence.presence || "We couldn't save that." }
    end
  end
end
