require "rails_helper"

RSpec.describe "EmailSubscribers", type: :request do
  describe "POST /subscribe" do
    let(:turbo_headers) { { "Accept" => "text/vnd.turbo-stream.html" } }

    it "creates a subscriber with the correct source and renders a Turbo Stream confirmation" do
      expect {
        post "/subscribe",
             params: { email: "ada@example.com", source: "footer" },
             headers: turbo_headers
      }.to change(EmailSubscriber, :count).by(1)

      sub = EmailSubscriber.last
      expect(sub.email).to eq("ada@example.com")
      expect(sub.source).to eq("footer")
      expect(sub.active?).to be true

      expect(response).to have_http_status(:ok)
      expect(response.media_type).to include("turbo-stream")
      expect(response.body).to include("email-capture-footer")
      expect(response.body).to include("See you tomorrow morning.")
    end

    it "enqueues a WelcomeEmailJob on successful new signup" do
      expect {
        post "/subscribe",
             params: { email: "new@example.com", source: "inline" },
             headers: turbo_headers
      }.to have_enqueued_job(WelcomeEmailJob)
    end

    it "is idempotent when the same email subscribes again while active (no extra welcome)" do
      sub = create(:email_subscriber, email: "repeat@example.com", source: "footer")

      expect(EmailSubscriber.count).to eq(1)
      expect {
        post "/subscribe",
             params: { email: "repeat@example.com", source: "footer" },
             headers: turbo_headers
      }.not_to have_enqueued_job(WelcomeEmailJob)
      expect(EmailSubscriber.count).to eq(1)

      expect(response.body).to include("See you tomorrow morning.")
      expect(sub.reload.active?).to be true
    end

    it "matches emails case-insensitively when checking existing subscribers" do
      create(:email_subscriber, email: "MIXED@example.com", source: "footer")

      expect {
        post "/subscribe",
             params: { email: "mixed@EXAMPLE.com", source: "footer" },
             headers: turbo_headers
      }.not_to change(EmailSubscriber, :count)
    end

    it "re-subscribes an unsubscribed row and re-enqueues the welcome email" do
      sub = create(:email_subscriber, :unsubscribed, email: "back@example.com", source: "footer")

      expect {
        post "/subscribe",
             params: { email: "back@example.com", source: "inline" },
             headers: turbo_headers
      }.to have_enqueued_job(WelcomeEmailJob).with(sub.id)

      sub.reload
      expect(sub.active?).to be true
      expect(sub.unsubscribed_at).to be_nil
      expect(response.body).to include("See you tomorrow morning.")
    end

    it "renders a frame replacement with an inline error and creates no row when the email is invalid" do
      expect {
        post "/subscribe",
             params: { email: "not-an-email", source: "footer" },
             headers: turbo_headers
      }.not_to change(EmailSubscriber, :count)

      expect(enqueued_jobs.select { |j| j[:job] == WelcomeEmailJob }).to be_empty
      expect(response).to have_http_status(:unprocessable_entity)
      expect(response.body).to include("email-capture-footer")
      # The form is re-rendered with crimson border styling and an inline help line.
      expect(response.body).to include("#C8102E")
      expect(response.body).not_to include("See you tomorrow morning.")
    end

    it "falls back to source=manual when an unknown source is submitted" do
      post "/subscribe",
           params: { email: "weird@example.com", source: "billboard" },
           headers: turbo_headers

      expect(EmailSubscriber.last.source).to eq("manual")
    end

    it "renders an inline turnstile failure when verification is forced to fail" do
      expect {
        post "/subscribe",
             params: { email: "blocked@example.com", source: "footer", "cf-turnstile-response" => "FORCE_FAIL" },
             headers: turbo_headers
      }.not_to change(EmailSubscriber, :count)

      expect(response).to have_http_status(:unprocessable_entity)
      expect(response.body).to include("email-capture-footer")
      expect(response.body).to include("couldn&#39;t verify you&#39;re human").or include("couldn't verify you're human")
    end
  end

  describe "GET /unsubscribe/:token" do
    it "renders the confirmation page when the token exists" do
      sub = create(:email_subscriber, email: "leaving@example.com")
      get "/unsubscribe/#{sub.token}"

      expect(response).to have_http_status(:ok)
      expect(response.body).to include("leaving@example.com")
      expect(response.body).to include("Stop the morning notes")
    end

    it "returns 404 when the token is unknown" do
      get "/unsubscribe/does-not-exist"
      expect(response).to have_http_status(:not_found)
    end
  end

  describe "DELETE /unsubscribe/:token" do
    it "calls unsubscribe! and renders the acknowledgement page" do
      sub = create(:email_subscriber, email: "goodbye@example.com")

      delete "/unsubscribe/#{sub.token}"

      expect(sub.reload.active?).to be false
      expect(sub.unsubscribed_at).to be_present
      expect(response).to have_http_status(:ok)
      expect(response.body).to include("You won't hear from us again.")
    end

    it "is idempotent on an already-unsubscribed row" do
      sub = create(:email_subscriber, :unsubscribed, email: "twice@example.com")
      original_time = sub.unsubscribed_at

      delete "/unsubscribe/#{sub.token}"

      expect(response).to have_http_status(:ok)
      expect(sub.reload.unsubscribed_at).to be_within(1.second).of(original_time)
    end

    it "returns 404 when the token is unknown" do
      delete "/unsubscribe/does-not-exist"
      expect(response).to have_http_status(:not_found)
    end
  end
end
