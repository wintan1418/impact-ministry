require "rails_helper"

RSpec.describe "EventRsvps", type: :request do
  let(:turbo_headers) { { "Accept" => "text/vnd.turbo-stream.html" } }

  describe "POST /events/:slug/rsvp" do
    it "creates an RSVP and renders a Turbo Stream confirmation" do
      event = create(:event, title: "First Light Brunch")

      expect {
        post "/events/#{event.slug}/rsvp",
             params: {
               event_rsvp: {
                 name: "Ada Lovelace",
                 email: "ada@example.com",
                 party_size: 2,
                 notes: "Bringing a friend."
               }
             },
             headers: turbo_headers
      }.to change(EventRsvp, :count).by(1)

      rsvp = EventRsvp.last
      expect(rsvp.email).to eq("ada@example.com")
      expect(rsvp.party_size).to eq(2)
      expect(rsvp.event).to eq(event)

      expect(response).to have_http_status(:ok)
      expect(response.media_type).to include("turbo-stream")
      expect(response.body).to include("rsvp-form")
      expect(response.body).to include("Your seat is saved")
    end

    it "re-renders the form with inline errors on bad email" do
      event = create(:event)

      expect {
        post "/events/#{event.slug}/rsvp",
             params: {
               event_rsvp: { name: "Ada", email: "not-an-email", party_size: 1 }
             },
             headers: turbo_headers
      }.not_to change(EventRsvp, :count)

      expect(response).to have_http_status(:unprocessable_entity)
      expect(response.body).to include("rsvp-form")
      expect(response.body).to include("Save my seat")
      expect(response.body).to include("Email")
    end

    it "re-renders with an error when the email is already RSVPed" do
      event = create(:event)
      create(:event_rsvp, event: event, email: "dup@example.com")

      expect {
        post "/events/#{event.slug}/rsvp",
             params: {
               event_rsvp: { name: "Ada", email: "DUP@example.com", party_size: 1 }
             },
             headers: turbo_headers
      }.not_to change(EventRsvp, :count)

      expect(response).to have_http_status(:unprocessable_entity)
      expect(response.body).to include("Save my seat")
    end

    it "blocks an RSVP that would exceed remaining seats" do
      event = create(:event, :capped, capacity: 3)
      create(:event_rsvp, event: event, party_size: 2)

      expect {
        post "/events/#{event.slug}/rsvp",
             params: {
               event_rsvp: { name: "Big Group", email: "lots@example.com", party_size: 4 }
             },
             headers: turbo_headers
      }.not_to change(EventRsvp, :count)

      expect(response).to have_http_status(:unprocessable_entity)
      expect(response.body).to include("Save my seat")
    end

    it "blocks an RSVP when Turnstile verification fails" do
      event = create(:event)

      expect {
        post "/events/#{event.slug}/rsvp",
             params: {
               event_rsvp: { name: "Ada", email: "ada@example.com", party_size: 1 },
               "cf-turnstile-response" => "FORCE_FAIL"
             },
             headers: turbo_headers
      }.not_to change(EventRsvp, :count)

      expect(response).to have_http_status(:unprocessable_entity)
      expect(response.body).to include("Save my seat")
    end

    it "404s when the event slug is unknown" do
      post "/events/does-not-exist/rsvp",
           params: { event_rsvp: { name: "x", email: "x@example.com", party_size: 1 } },
           headers: turbo_headers

      expect(response).to have_http_status(:not_found)
    end
  end
end
