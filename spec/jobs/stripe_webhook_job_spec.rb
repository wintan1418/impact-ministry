require "rails_helper"

RSpec.describe StripeWebhookJob, type: :job do
  let(:payload) do
    {
      id: "evt_test_999",
      type: "checkout.session.completed",
      data: {
        object: {
          id: "cs_test_xyz",
          object: "checkout.session",
          payment_status: "paid",
          mode: "payment",
          payment_intent: "pi_test_xyz",
          amount_total: 7_500,
          currency: "usd",
          customer: "cus_test_xyz",
          customer_email: "donor@example.com",
          metadata: { designation: "general", frequency: "once" }
        }
      }
    }.to_json
  end

  before do
    # Bypass signature verification — covered by the controller spec.
    allow(ENV).to receive(:[]).and_call_original
    allow(ENV).to receive(:[]).with("STRIPE_WEBHOOK_SECRET").and_return(nil)
  end

  it "creates a ProcessedStripeEvent row and dispatches the handler" do
    expect {
      described_class.perform_now(payload: payload, signature: nil)
    }.to change(ProcessedStripeEvent, :count).by(1)
      .and change(Donation, :count).by(1)
  end

  it "is idempotent on replay" do
    described_class.perform_now(payload: payload, signature: nil)
    expect {
      described_class.perform_now(payload: payload, signature: nil)
    }.not_to change(Donation, :count)
  end

  it "ignores unknown event types" do
    other = payload.sub('"checkout.session.completed"', '"customer.created"')
    expect {
      described_class.perform_now(payload: other, signature: nil)
    }.not_to change(Donation, :count)
  end
end
