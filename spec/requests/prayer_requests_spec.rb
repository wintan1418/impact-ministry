require "rails_helper"

RSpec.describe "PrayerRequests", type: :request do
  let(:turbo_headers) { { "Accept" => "text/vnd.turbo-stream.html" } }

  describe "GET /pray" do
    it "renders the form and a quiet empty-state when no public requests exist" do
      get "/pray"
      expect(response).to have_http_status(:ok)
      expect(response.body).to include("Tell us what to")
      expect(response.body).to include("prayer-form")
    end

    it "renders only visible public requests on the wall" do
      visible    = create(:prayer_request, :public_praying, body: "VISIBLE_BODY_TEXT_FOR_TEST")
      hidden_new = create(:prayer_request, body: "PRIVATE_NEW_BODY_HIDDEN_FROM_WALL")
      private_pr = create(:prayer_request, status: "praying", is_public: false, body: "INTERNAL_BODY_NOT_PUBLIC")
      archived   = create(:prayer_request, status: "archived", is_public: true, body: "ARCHIVED_BODY_HIDDEN")

      get "/pray"

      expect(response.body).to include(visible.body)
      expect(response.body).not_to include(hidden_new.body)
      expect(response.body).not_to include(private_pr.body)
      expect(response.body).not_to include(archived.body)
    end

    it "filters to answered when ?filter=answered is set" do
      praying  = create(:prayer_request, :public_praying, body: "PRAYING_ONLY_BODY")
      answered = create(:prayer_request, :answered,       body: "ANSWERED_BODY_VISIBLE")

      get "/pray", params: { filter: "answered" }

      expect(response.body).to include(answered.body)
      expect(response.body).not_to include(praying.body)
    end
  end

  describe "POST /pray" do
    it "creates a new PrayerRequest with status 'new' and returns a Turbo Stream confirmation" do
      expect {
        post "/pray",
             params: { prayer_request: { body: "Please pray for my mother after the diagnosis.", name: "Daniel R." } },
             headers: turbo_headers
      }.to change(PrayerRequest, :count).by(1)

      pr = PrayerRequest.last
      expect(pr.status).to eq("new")
      expect(pr.is_public).to be false
      expect(pr.name).to eq("Daniel R.")
      expect(pr.body).to include("mother after the diagnosis")

      expect(response).to have_http_status(:ok)
      expect(response.media_type).to include("turbo-stream")
      expect(response.body).to include("prayer-form")
      expect(response.body).to include("We've received your prayer.")
    end

    it "honors the anonymous toggle" do
      post "/pray",
           params: { prayer_request: { body: "A quiet request, please.", is_anonymous: "1" } },
           headers: turbo_headers

      expect(PrayerRequest.last.is_anonymous).to be true
    end

    it "re-renders the form with inline errors when body is too short" do
      expect {
        post "/pray",
             params: { prayer_request: { body: "hi" } },
             headers: turbo_headers
      }.not_to change(PrayerRequest, :count)

      expect(response).to have_http_status(:unprocessable_entity)
      expect(response.body).to include("prayer-form")
      expect(response.body).not_to include("We've received your prayer.")
      # Inline error visible somewhere in the rendered frame.
      expect(response.body).to match(/too short|at least 6|6 characters/i)
    end

    it "re-renders with an inline error when turnstile is forced to fail" do
      expect {
        post "/pray",
             params: {
               prayer_request: { body: "Please pray for our small church." },
               "cf-turnstile-response" => "FORCE_FAIL"
             },
             headers: turbo_headers
      }.not_to change(PrayerRequest, :count)

      expect(response).to have_http_status(:unprocessable_entity)
      expect(response.body).to match(/verify you(&#39;|')re human/)
    end

    it "rejects a malformed email inline" do
      expect {
        post "/pray",
             params: { prayer_request: { body: "Please pray for clarity at work.", email: "not-an-email" } },
             headers: turbo_headers
      }.not_to change(PrayerRequest, :count)

      expect(response).to have_http_status(:unprocessable_entity)
      expect(response.body).to include("prayer-form")
    end
  end

  describe "POST /pray/:id/prayed" do
    let!(:request_record) { create(:prayer_request, :public_praying, prayed_count: 4) }

    it "increments the prayed_count and replaces the per-card counter frame" do
      expect {
        post "/pray/#{request_record.id}/prayed", headers: turbo_headers
      }.to change { request_record.reload.prayed_count }.from(4).to(5)

      expect(response).to have_http_status(:ok)
      expect(response.media_type).to include("turbo-stream")
      expect(response.body).to include("prayed_#{request_record.id}")
      expect(response.body).to include("5")
    end

    it "is session-deduped — a second tap from the same session does not increment" do
      post "/pray/#{request_record.id}/prayed", headers: turbo_headers
      expect(request_record.reload.prayed_count).to eq(5)

      expect {
        post "/pray/#{request_record.id}/prayed", headers: turbo_headers
      }.not_to change { request_record.reload.prayed_count }
    end

    it "returns 404 for a request not in the visible scope" do
      private_pr = create(:prayer_request, status: "new", is_public: false)
      post "/pray/#{private_pr.id}/prayed", headers: turbo_headers
      expect(response).to have_http_status(:not_found)
    end

    it "returns 404 for an archived request" do
      archived = create(:prayer_request, status: "archived", is_public: true)
      post "/pray/#{archived.id}/prayed", headers: turbo_headers
      expect(response).to have_http_status(:not_found)
    end
  end
end
