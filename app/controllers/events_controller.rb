# Public events surface. Anonymous read access — no authentication. RSVPs are
# handled by EventRsvpsController. See docs/ROUTES.md and CLAUDE.md §4.
class EventsController < ApplicationController
  before_action :set_event, only: :show

  # GET /events
  def index
    @upcoming = Event.published.upcoming.chronological.limit(20)
    @past     = Event.published.past.reverse_chronological.limit(10)
  end

  # GET /events/:slug
  def show
    @event_rsvp = EventRsvp.new(event: @event)
  end

  private

  def set_event
    # Scoped to published — an unpublished slug yields a 404 to anonymous users.
    @event = Event.published.friendly.find(params[:slug])
  end
end
