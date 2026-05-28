require "rails_helper"

RSpec.describe "Events", type: :request do
  describe "GET /events" do
    it "renders the upcoming and past sections" do
      upcoming = create(:event, title: "First Light Brunch", starts_at: 1.week.from_now)
      past     = create(:event, :past,  title: "Lenten Retreat 2026")

      get "/events"

      expect(response).to have_http_status(:ok)
      expect(response.body).to include(upcoming.title)
      expect(response.body).to include(past.title)
    end

    it "hides unpublished events" do
      hidden = create(:event, :unpublished, title: "Secret Workshop")

      get "/events"

      expect(response).to have_http_status(:ok)
      expect(response.body).not_to include(hidden.title)
    end

    it "renders the empty state when nothing is scheduled" do
      get "/events"
      expect(response).to have_http_status(:ok)
      expect(response.body).to include("next gathering is being planned")
    end
  end

  describe "GET /events/:slug" do
    it "renders a published event with its RSVP form" do
      event = create(:event, title: "Partners Roundtable", starts_at: 2.weeks.from_now)

      get "/events/#{event.slug}"

      expect(response).to have_http_status(:ok)
      expect(response.body).to include(event.title)
      expect(response.body).to include("Save my seat")
      expect(response.body).to include("rsvp-form")
    end

    it "shows the at-capacity message when the event is full" do
      event = create(:event, :capped, capacity: 2)
      create(:event_rsvp, event: event, party_size: 2)

      get "/events/#{event.slug}"

      expect(response.body).to include("We're at capacity")
      expect(response.body).not_to include("Save my seat")
    end

    it "shows the gathering-passed message when the event is over" do
      event = create(:event, :past, title: "Walked Already")

      get "/events/#{event.slug}"

      expect(response.body).to include("This gathering has passed")
      expect(response.body).not_to include("Save my seat")
    end

    it "404s an unpublished event" do
      hidden = create(:event, :unpublished)

      get "/events/#{hidden.slug}"

      expect(response).to have_http_status(:not_found)
    end

    it "404s an unknown slug" do
      get "/events/does-not-exist"
      expect(response).to have_http_status(:not_found)
    end
  end
end
