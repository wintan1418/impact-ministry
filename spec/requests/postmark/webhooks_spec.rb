require "rails_helper"

RSpec.describe "Postmark::Webhooks", type: :request do
  describe "POST /postmark/webhooks" do
    context "without webhook auth configured (default in test)" do
      around do |example|
        old_u = ENV.delete("POSTMARK_WEBHOOK_USERNAME")
        old_p = ENV.delete("POSTMARK_WEBHOOK_PASSWORD")
        example.run
      ensure
        ENV["POSTMARK_WEBHOOK_USERNAME"] = old_u if old_u
        ENV["POSTMARK_WEBHOOK_PASSWORD"] = old_p if old_p
      end

      it "accepts a valid Open payload, returns 200, and enqueues a processing job" do
        payload = {
          RecordType: "Open",
          MessageID:  "pm-test-1",
          ReceivedAt: "2026-05-27T12:34:56Z"
        }

        expect {
          post "/postmark/webhooks", params: payload, as: :json
        }.to have_enqueued_job(ProcessPostmarkWebhookJob)

        expect(response).to have_http_status(:ok)
      end

      it "returns 200 even on a payload missing RecordType (Postmark must not retry)" do
        post "/postmark/webhooks", params: {}, as: :json
        expect(response).to have_http_status(:ok)
      end
    end

    context "with webhook auth configured" do
      around do |example|
        ENV["POSTMARK_WEBHOOK_USERNAME"] = "pm-user"
        ENV["POSTMARK_WEBHOOK_PASSWORD"] = "pm-pass"
        example.run
      ensure
        ENV.delete("POSTMARK_WEBHOOK_USERNAME")
        ENV.delete("POSTMARK_WEBHOOK_PASSWORD")
      end

      it "rejects requests with missing or wrong basic auth credentials" do
        post "/postmark/webhooks",
             params: { RecordType: "Open", MessageID: "x" },
             as: :json,
             headers: { "HTTP_AUTHORIZATION" => ActionController::HttpAuthentication::Basic.encode_credentials("wrong", "creds") }

        expect(response).to have_http_status(:unauthorized)
      end

      it "accepts requests with correct basic auth credentials" do
        post "/postmark/webhooks",
             params: { RecordType: "Open", MessageID: "x" },
             as: :json,
             headers: { "HTTP_AUTHORIZATION" => ActionController::HttpAuthentication::Basic.encode_credentials("pm-user", "pm-pass") }

        expect(response).to have_http_status(:ok)
      end
    end
  end
end
