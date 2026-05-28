require "rails_helper"

RSpec.describe "Partnerships", type: :request do
  let(:turbo_headers) { { "Accept" => "text/vnd.turbo-stream.html" } }
  let(:valid_attrs) do
    {
      partnership: {
        organization_name: "Cedar Grove Church",
        contact_name:      "Marcus Levine",
        contact_email:     "marcus@cedargrove.example",
        contact_phone:     "601-555-0143",
        organization_type: "church",
        interest_areas:    %w[devotionals podcast],
        message:           "We'd love to talk about co-publishing a devotional series this fall."
      }
    }
  end

  describe "GET /partner" do
    it "renders the intake form with the editorial hero and audience cards" do
      get "/partner"
      expect(response).to have_http_status(:ok)
      expect(response.body).to include("partnership-form")
      expect(response.body).to include("Let&#39;s build something")
      expect(response.body).to include("For churches")
      expect(response.body).to include("For nonprofits &amp; schools")
      expect(response.body).to include("For businesses")
      expect(response.body).to include("Send")
    end
  end

  describe "POST /partner" do
    it "creates a Partnership (status=new), enqueues the notification job, and returns a Turbo Stream confirmation" do
      expect {
        expect {
          post "/partner", params: valid_attrs, headers: turbo_headers
        }.to change(Partnership, :count).by(1)
      }.to have_enqueued_job(PartnershipNotificationJob).on_queue("mailers")

      partnership = Partnership.last
      expect(partnership.organization_name).to eq("Cedar Grove Church")
      expect(partnership.contact_email).to     eq("marcus@cedargrove.example")
      expect(partnership.organization_type).to eq("church")
      expect(partnership.interest_areas).to    contain_exactly("devotionals", "podcast")
      expect(partnership.status).to eq("new")

      expect(response).to have_http_status(:ok)
      expect(response.media_type).to include("turbo-stream")
      expect(response.body).to include("partnership-form")
      expect(response.body).to include("Thank you.")
      expect(response.body).to include("A real person on our team")
    end

    it "accepts a submission with no interest_areas selected" do
      # The form ships a hidden "" so an unchecked checkbox group still
      # arrives as an array. Mirror that in the test.
      attrs = valid_attrs.deep_merge(partnership: { interest_areas: [ "" ] })

      expect {
        post "/partner", params: attrs, headers: turbo_headers
      }.to change(Partnership, :count).by(1)

      expect(Partnership.last.interest_areas).to eq([])
      expect(response).to have_http_status(:ok)
    end

    it "accepts a submission with no phone number" do
      attrs = valid_attrs.deep_merge(partnership: { contact_phone: "" })

      expect {
        post "/partner", params: attrs, headers: turbo_headers
      }.to change(Partnership, :count).by(1)

      expect(Partnership.last.contact_phone).to be_blank
    end

    it "re-renders the form with inline errors when message is too short" do
      attrs = valid_attrs.deep_merge(partnership: { message: "hi" })

      expect {
        post "/partner", params: attrs, headers: turbo_headers
      }.not_to change(Partnership, :count)

      expect(response).to have_http_status(:unprocessable_entity)
      expect(response.body).to include("partnership-form")
      expect(response.body).not_to include("A real person on our team")
      expect(response.body).to match(/too short|at least 10|10 characters/i)
    end

    it "re-renders the form with inline errors when contact_email is malformed" do
      attrs = valid_attrs.deep_merge(partnership: { contact_email: "not-an-email" })

      expect {
        post "/partner", params: attrs, headers: turbo_headers
      }.not_to change(Partnership, :count)

      expect(response).to have_http_status(:unprocessable_entity)
      expect(response.body).to include("partnership-form")
      expect(response.body).to match(/email/i)
    end

    it "re-renders with an inline error when turnstile is forced to fail" do
      attrs = valid_attrs.merge("cf-turnstile-response" => "FORCE_FAIL")

      expect {
        post "/partner", params: attrs, headers: turbo_headers
      }.not_to change(Partnership, :count)

      expect(response).to have_http_status(:unprocessable_entity)
      expect(response.body).to include("partnership-form")
      expect(response.body).to match(/verify you(&#39;|')re human/)
    end

    it "does not enqueue the notification job when validation fails" do
      attrs = valid_attrs.deep_merge(partnership: { message: "hi" })

      expect {
        post "/partner", params: attrs, headers: turbo_headers
      }.not_to have_enqueued_job(PartnershipNotificationJob)
    end
  end
end
