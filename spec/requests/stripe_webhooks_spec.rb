require "rails_helper"

RSpec.describe "Stripe webhooks", type: :request do
  let(:secret) { "whsec_test_secret" }
  let(:payload) { { id: "evt_test_sig", type: "customer.created", data: { object: {} } }.to_json }

  describe "POST /stripe/webhooks" do
    around do |ex|
      ClimateControl.modify(STRIPE_WEBHOOK_SECRET: secret) { ex.run }
    rescue NameError
      # ClimateControl isn't in the bundle — fall back to ENV stubbing.
      original = ENV["STRIPE_WEBHOOK_SECRET"]
      ENV["STRIPE_WEBHOOK_SECRET"] = secret
      ex.run
      ENV["STRIPE_WEBHOOK_SECRET"] = original
    end

    it "rejects an invalid signature" do
      post "/stripe/webhooks", params: payload,
           headers: { "Content-Type" => "application/json", "Stripe-Signature" => "bad" }
      expect(response).to have_http_status(:bad_request)
    end

    it "accepts a valid signature and enqueues the job" do
      timestamp = Time.now.to_i
      signed_payload = "#{timestamp}.#{payload}"
      sig = OpenSSL::HMAC.hexdigest("SHA256", secret, signed_payload)
      header = "t=#{timestamp},v1=#{sig}"

      expect {
        post "/stripe/webhooks", params: payload,
             headers: { "Content-Type" => "application/json", "Stripe-Signature" => header }
      }.to have_enqueued_job(StripeWebhookJob)

      expect(response).to have_http_status(:ok)
    end
  end

  describe "POST /stripe/webhooks (no secret set)" do
    it "still ingests the event (dev fallback)" do
      original = ENV["STRIPE_WEBHOOK_SECRET"]
      ENV["STRIPE_WEBHOOK_SECRET"] = nil
      begin
        expect {
          post "/stripe/webhooks", params: payload, headers: { "Content-Type" => "application/json" }
        }.to have_enqueued_job(StripeWebhookJob)
        expect(response).to have_http_status(:ok)
      ensure
        ENV["STRIPE_WEBHOOK_SECRET"] = original
      end
    end
  end
end
