require "rails_helper"

RSpec.describe "FeedbackMessages", type: :request do
  let(:turbo_headers) { { "Accept" => "text/vnd.turbo-stream.html" } }
  let(:valid_attrs) do
    {
      feedback_message: {
        name: "Marcus L.",
        email: "marcus@example.com",
        subject: "A short note",
        body: "Thank you for the morning devotional — it found me at the kitchen table.",
        kind: "general"
      }
    }
  end

  describe "GET /contact" do
    before do
      Page.find_or_create_by!(slug: "contact") do |p|
        p.title     = "Contact us"
        p.body      = "<p>Write to us.</p>"
        p.published = true
      end
    end

    it "renders the contact page with the form embedded" do
      get "/contact"
      expect(response).to have_http_status(:ok)
      expect(response.body).to include("feedback-form")
      expect(response.body).to include("Send")
    end
  end

  describe "POST /contact" do
    it "creates a FeedbackMessage, enqueues a notification job, and returns a Turbo Stream confirmation" do
      expect {
        expect {
          post "/contact", params: valid_attrs, headers: turbo_headers
        }.to change(FeedbackMessage, :count).by(1)
      }.to have_enqueued_job(FeedbackNotificationJob).on_queue("mailers")

      msg = FeedbackMessage.last
      expect(msg.name).to eq("Marcus L.")
      expect(msg.email).to eq("marcus@example.com")
      expect(msg.kind).to eq("general")
      expect(msg.replied).to be false

      expect(response).to have_http_status(:ok)
      expect(response.media_type).to include("turbo-stream")
      expect(response.body).to include("feedback-form")
      expect(response.body).to include("We received your note.")
    end

    it "honors the kind parameter" do
      attrs = valid_attrs.deep_merge(feedback_message: { kind: "partnership" })
      post "/contact", params: attrs, headers: turbo_headers
      expect(FeedbackMessage.last.kind).to eq("partnership")
    end

    it "re-renders the form with inline errors when body is too short" do
      attrs = valid_attrs.deep_merge(feedback_message: { body: "hi" })

      expect {
        post "/contact", params: attrs, headers: turbo_headers
      }.not_to change(FeedbackMessage, :count)

      expect(response).to have_http_status(:unprocessable_entity)
      expect(response.body).to include("feedback-form")
      expect(response.body).not_to include("We received your note.")
      expect(response.body).to match(/too short|at least 6|6 characters/i)
    end

    it "re-renders the form with inline errors when email is malformed" do
      attrs = valid_attrs.deep_merge(feedback_message: { email: "not-an-email" })

      expect {
        post "/contact", params: attrs, headers: turbo_headers
      }.not_to change(FeedbackMessage, :count)

      expect(response).to have_http_status(:unprocessable_entity)
      expect(response.body).to include("feedback-form")
      expect(response.body).to match(/email/i)
    end

    it "re-renders with an inline error when turnstile is forced to fail" do
      attrs = valid_attrs.merge("cf-turnstile-response" => "FORCE_FAIL")

      expect {
        post "/contact", params: attrs, headers: turbo_headers
      }.not_to change(FeedbackMessage, :count)

      expect(response).to have_http_status(:unprocessable_entity)
      expect(response.body).to include("feedback-form")
      expect(response.body).to match(/verify you(&#39;|')re human/)
    end

    it "does not enqueue the notification job when validation fails" do
      attrs = valid_attrs.deep_merge(feedback_message: { body: "hi" })

      expect {
        post "/contact", params: attrs, headers: turbo_headers
      }.not_to have_enqueued_job(FeedbackNotificationJob)
    end
  end
end
