# Public RSVP submission. Turnstile-protected. One row per email per event.
# Responds with a Turbo Stream replacement of the `rsvp-form` frame on the
# event show page; HTML fallback redirects with a flash notice.
#
# See CLAUDE.md §3 (errors render inline, no toasts).
class EventRsvpsController < ApplicationController
  include TurnstileProtectable

  before_action :set_event

  # POST /events/:event_slug/rsvp
  def create
    @event_rsvp = @event.event_rsvps.build(event_rsvp_params)

    unless verify_turnstile!
      flash.delete(:alert)
      @error_message = "We couldn't verify you're human. Please try again."
      respond_failure
      return
    end

    if @event_rsvp.save
      respond_success
    else
      @error_message = @event_rsvp.errors.full_messages.first.presence ||
                       "We couldn't save your seat — please check the form below."
      respond_failure
    end
  end

  private

  def set_event
    @event = Event.published.friendly.find(params[:event_slug])
  end

  def event_rsvp_params
    params.require(:event_rsvp).permit(:name, :email, :party_size, :notes)
  end

  def respond_success
    respond_to do |format|
      format.turbo_stream { render :create, status: :ok }
      format.html         { redirect_to event_path(@event), notice: "Your seat is saved." }
    end
  end

  def respond_failure
    respond_to do |format|
      format.turbo_stream { render :create, status: :unprocessable_entity }
      format.html do
        # Re-render the show page with the failed RSVP so errors appear inline.
        @event = @event
        @event_rsvp ||= EventRsvp.new(event: @event)
        render "events/show", status: :unprocessable_entity
      end
    end
  end
end
