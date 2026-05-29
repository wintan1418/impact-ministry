require "rails_helper"

RSpec.describe Giving::Webhooks::CheckoutSessionCompleted do
  let(:session_payload) do
    {
      id: "cs_test_abc",
      object: "checkout.session",
      payment_status: "paid",
      mode: "payment",
      payment_intent: "pi_test_abc",
      amount_total: 5_000,
      currency: "usd",
      customer: "cus_test_abc",
      customer_email: "donor@example.com",
      metadata: {
        designation: "youth",
        frequency: "once",
        donor_email: "donor@example.com",
        donor_name: "Mary R"
      }
    }
  end
  let(:event) do
    Stripe::Event.construct_from(
      id: "evt_test_1",
      type: "checkout.session.completed",
      data: { object: session_payload }
    )
  end

  it "creates a Donor and a Donation" do
    expect {
      described_class.call(event)
    }.to change(Donor, :count).by(1).and change(Donation, :count).by(1)

    donation = Donation.last
    expect(donation.amount_cents).to eq(5_000)
    expect(donation.designation).to eq("youth")
    expect(donation.frequency).to eq("once")
    expect(donation.status).to eq("succeeded")
    expect(donation.donor.email).to eq("donor@example.com")
    expect(donation.donor.stripe_customer_id).to eq("cus_test_abc")
  end

  it "queues a receipt" do
    expect {
      described_class.call(event)
    }.to have_enqueued_job(Giving::DonationReceiptJob)
  end

  it "is idempotent on the checkout session id" do
    described_class.call(event)
    expect {
      described_class.call(event)
    }.not_to change(Donation, :count)
  end

  it "marks subscription mode as monthly" do
    sub_payload = session_payload.merge(mode: "subscription", subscription: "sub_test_abc")
    sub_event   = Stripe::Event.construct_from(
      id: "evt_test_2",
      type: "checkout.session.completed",
      data: { object: sub_payload }
    )

    described_class.call(sub_event)
    expect(Donation.last.frequency).to eq("monthly")
    expect(Donation.last.stripe_subscription_id).to eq("sub_test_abc")
  end

  it "links to an existing user by email when possible" do
    create(:user, email_address: "donor@example.com")
    described_class.call(event)
    expect(Donation.last.donor.user).to be_present
  end
end
